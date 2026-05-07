// mindLAMP

import AVFoundation
import Foundation

enum VideoMultipartUploadError: Error, LocalizedError {
    case fileNotReadable
    case unexpectedReadSize(expected: Int, actual: Int)
    case missingETag(partNumber: Int)
    case uploadPartHTTP(status: Int, partNumber: Int)
    case initiateMissingParts

    var errorDescription: String? {
        switch self {
        case .fileNotReadable:
            return "Could not read the recorded video file."
        case let .unexpectedReadSize(expected, actual):
            return "Read \(actual) bytes, expected \(expected)."
        case let .missingETag(part):
            return "S3 response missing ETag for part \(part)."
        case let .uploadPartHTTP(status, part):
            return "Part \(part) upload failed with HTTP \(status)."
        case .initiateMissingParts:
            return "Server did not return upload parts."
        }
    }
}

private actor UploadPartURLRegistry {
    private var partsByNumber: [Int: VideoUploadPartDescriptor]
    private(set) var expiresAt: TimeInterval

    init(parts: [VideoUploadPartDescriptor], expiresAt: TimeInterval) {
        self.partsByNumber = Dictionary(uniqueKeysWithValues: parts.map { ($0.partNumber, $0) })
        self.expiresAt = expiresAt
    }

    func descriptor(for partNumber: Int) -> VideoUploadPartDescriptor? {
        partsByNumber[partNumber]
    }

    func applyRefresh(_ response: VideoUploadRefreshURLsResponse) {
        expiresAt = response.expiresAt
        for p in response.parts {
            partsByNumber[p.partNumber] = p
        }
    }
}

/// Orchestrates initiate → parallel S3 PUTs (with optional presigned URL refresh) → complete.
final class VideoMultipartUploadService: @unchecked Sendable {

    private let apiClient: VideoUploadAPIClient
    private let uploadSession: URLSession
    private let maxConcurrentPartUploads: Int
    private var participantId: String
    init(
        configuration: VideoDiary.VideoUploadConfiguration,
        uploadSession: URLSession? = nil
    ) {
        self.participantId = configuration.participantId
        self.apiClient = VideoUploadAPIClient(configuration: configuration)
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 600
        config.timeoutIntervalForResource = 3_600
        config.waitsForConnectivity = true
        self.uploadSession = uploadSession ?? URLSession(configuration: config)
        self.maxConcurrentPartUploads = 5
    }

    /// One-shot upload (no persistence hooks). On failure, tells the server to **abort** the multipart session.
    func uploadRecordedVideo(
        fileURL: URL,
        recordingConfiguration: VideoDiary.RecordingConfiguration,
        activityId: String,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        try await uploadResumable(
            fileURL: fileURL,
            recordingConfiguration: recordingConfiguration,
            activityId: activityId,
            resume: nil,
            shouldAbortRemoteSessionOnFailure: true,
            progress: progress,
            onInitiated: { _, _ in
                await Task.yield()
            },
            onPartUploaded: { _, _ in
                await Task.yield()
            }
        )
    }

    /// Multipart upload with optional resume and persistence hooks. Does **not** abort on failure when `shouldAbortRemoteSessionOnFailure` is `false` so the caller can retry after fixing connectivity.
    func uploadResumable(
        fileURL: URL,
        recordingConfiguration: VideoDiary.RecordingConfiguration,
        activityId: String,
        resume: VideoDiaryMultipartProgress?,
        shouldAbortRemoteSessionOnFailure: Bool,
        progress: @escaping @Sendable (Double) -> Void,
        onInitiated: @escaping @Sendable (VideoDiaryMultipartProgress, VideoUploadInitiatedMetadata) async throws -> Void,
        onPartUploaded: @escaping @Sendable (Int, String) async throws -> Void
    ) async throws {
        videoDiaryUploadLog(
            "uploadResumable: START file=\(fileURL.lastPathComponent) activityId=\(activityId) resume=\(resume != nil) abortOnFailure=\(shouldAbortRemoteSessionOnFailure)"
        )
        let sessionID: String
        let sortedParts: [VideoUploadPartDescriptor]
        let registry: UploadPartURLRegistry

        if let resume {
            sessionID = resume.id
            sortedParts = resume.partDescriptors.sorted { $0.partNumber < $1.partNumber }
            registry = UploadPartURLRegistry(parts: resume.partDescriptors, expiresAt: resume.expiresAt)
            let done = resume.completedPartETags.count
            videoDiaryUploadLog(
                "uploadResumable: RESUME session=\(sessionID) partsTotal=\(sortedParts.count) alreadyUploaded=\(done) expiresAt=\(resume.expiresAt)"
            )
        } else {
            let fileSize = try fileByteSize(at: fileURL)
            // MIME type of the file that will be PUT in parts (JSON field `contentType`); the initiate POST itself is `application/json`.
            let objectContentType = Self.mimeTypeForUploadedVideoFile(at: fileURL)
            let durationSeconds = await loadDurationSeconds(fileURL: fileURL)
            let (width, height) = await loadVideoDimensions(
                fileURL: fileURL,
                fallback: recordingConfiguration.resolution.pixelDimensions
            )

            let initiateBody = VideoUploadInitiateRequestBody(
//                activityId: activityId,
//                contentType: objectContentType,
                participantId: participantId,
                metadata: VideoUploadMetadataPayload(
                    size: fileSize,
                    codec: "h264",
                    bitrate: recordingConfiguration.bitratePerSecond,
                    duration: durationSeconds,
                    frameRate: recordingConfiguration.frameRate,
                    height: height,
                    width: width
                )
            )

            videoDiaryUploadLog(
                "uploadResumable: initiating multipart fileSizeBytes=\(fileSize) objectContentType=\(objectContentType) duration=\(durationSeconds)s dimensions=\(width)x\(height)"
            )
            let initiated = try await apiClient.initiate(body: initiateBody)
            guard !initiated.parts.isEmpty else {
                videoDiaryUploadLog("uploadResumable: initiate returned zero parts")
                throw VideoMultipartUploadError.initiateMissingParts
            }

            sessionID = initiated.id
            sortedParts = initiated.parts.sorted { $0.partNumber < $1.partNumber }
            registry = UploadPartURLRegistry(parts: initiated.parts, expiresAt: initiated.expiresAt)

            let initiateMetadata = VideoUploadInitiatedMetadata(
                participantId: participantId,
                activityId: activityId,
                durationSeconds: durationSeconds,
                width: width,
                height: height,
                fileSizeBytes: fileSize,
                mimeType: objectContentType
            )
            let snapshot = VideoDiaryMultipartProgress(
                id: sessionID,
                expiresAt: initiated.expiresAt,
                partDescriptors: initiated.parts,
                completedPartETags: [:]
            )
            try await onInitiated(snapshot, initiateMetadata)
        }

        var mergedETags = resume?.completedPartETags ?? [:]
        let baselineComplete = sortedParts.filter { mergedETags[$0.partNumber] != nil }.count

        do {
            let progressHook: @Sendable (Double) -> Void = { [sessionID] p in
                videoDiaryUploadLog("uploadResumable: PROGRESS session=\(sessionID) \(Int((p * 100).rounded()))%")
                progress(p)
            }
            mergedETags = try await uploadAllPartsParallel(
                fileURL: fileURL,
                sessionID: sessionID,
                parts: sortedParts,
                registry: registry,
                existingPartETags: mergedETags,
                baselineComplete: baselineComplete,
                progress: progressHook,
                onPartUploaded: onPartUploaded
            )

            let completeParts = try sortedParts.map { part -> VideoUploadCompletedPartPayload in
                guard let etag = mergedETags[part.partNumber] else {
                    throw VideoMultipartUploadError.missingETag(partNumber: part.partNumber)
                }
                return VideoUploadCompletedPartPayload(partNumber: part.partNumber, etag: etag)
            }
            videoDiaryUploadLog("uploadResumable: all parts uploaded, calling complete session=\(sessionID)")
            let completeBody = VideoUploadCompleteRequestBody(id: sessionID, parts: completeParts)
            try await apiClient.complete(body: completeBody)
            videoDiaryUploadLog("uploadResumable: FINISH OK session=\(sessionID) file=\(fileURL.lastPathComponent)")
        } catch {
            videoDiaryUploadLog("uploadResumable: ERROR session=\(sessionID) \(error.localizedDescription)")
            if shouldAbortRemoteSessionOnFailure {
                videoDiaryUploadLog("uploadResumable: aborting remote session session=\(sessionID)")
                try? await apiClient.abort(body: VideoUploadAbortRequestBody(id: sessionID))
            }
            throw error
        }
    }

    private func uploadAllPartsParallel(
        fileURL: URL,
        sessionID: String,
        parts sortedParts: [VideoUploadPartDescriptor],
        registry: UploadPartURLRegistry,
        existingPartETags: [Int: String],
        baselineComplete: Int,
        progress: @escaping @Sendable (Double) -> Void,
        onPartUploaded: @escaping @Sendable (Int, String) async throws -> Void
    ) async throws -> [Int: String] {
        var mergedETags = existingPartETags
        let total = sortedParts.count

        let pendingParts = sortedParts.filter { mergedETags[$0.partNumber] == nil }
        videoDiaryUploadLog(
            "uploadParts: session=\(sessionID) total=\(sortedParts.count) pending=\(pendingParts.count) baselineComplete=\(baselineComplete) concurrency=\(min(maxConcurrentPartUploads, pendingParts.count))"
        )
        guard !pendingParts.isEmpty else {
            videoDiaryUploadLog("uploadParts: nothing pending (all parts already had ETags), skipping PUTs")
            progress(1)
            return mergedETags
        }

        final class ProgressBox: @unchecked Sendable {
            /// Serializes counter updates from concurrent part uploads (no barrier needed on a serial queue).
            private let isolationQueue = DispatchQueue(label: "digital.lamp.VideoDiaryUpload.ProgressBox")
            private var finishedExtra = 0
            private let total: Int
            private let baseline: Int
            private let progress: @Sendable (Double) -> Void

            init(total: Int, baseline: Int, progress: @escaping @Sendable (Double) -> Void) {
                self.total = total
                self.baseline = baseline
                self.progress = progress
            }

            func bump() {
                let p = isolationQueue.sync { () -> Double in
                    finishedExtra += 1
                    return min(1, Double(baseline + finishedExtra) / Double(total))
                }
                progress(p)
            }
        }
        let box = ProgressBox(total: total, baseline: baselineComplete, progress: progress)

        let session = uploadSession
        let client = apiClient
        var nextPartIndex = 0
        try await withThrowingTaskGroup(of: (Int, String).self) { group in
            func enqueueNext() {
                guard nextPartIndex < pendingParts.count else { return }
                let part = pendingParts[nextPartIndex]
                nextPartIndex += 1
                group.addTask {
                    let etag = try await Self.uploadSinglePartWithRetries(
                        fileURL: fileURL,
                        part: part,
                        sessionID: sessionID,
                        registry: registry,
                        apiClient: client,
                        session: session
                    )
                    try await onPartUploaded(part.partNumber, etag)
                    box.bump()
                    return (part.partNumber, etag)
                }
            }

            let initial = min(maxConcurrentPartUploads, pendingParts.count)
            for _ in 0 ..< initial {
                enqueueNext()
            }

            while let (num, etag) = try await group.next() {
                mergedETags[num] = etag
                videoDiaryUploadLog("uploadParts: finished part \(num)/\(total) session=\(sessionID)")
                enqueueNext()
            }
        }

        videoDiaryUploadLog("uploadParts: all PUTs done session=\(sessionID) parts=\(total)")
        return mergedETags
    }

    private static func uploadSinglePartWithRetries(
        fileURL: URL,
        part: VideoUploadPartDescriptor,
        sessionID: String,
        registry: UploadPartURLRegistry,
        apiClient: VideoUploadAPIClient,
        session: URLSession
    ) async throws -> String {
        var refreshCount = 0
        let maxRefresh = 4
        videoDiaryUploadLog(
            "partUpload: START part=\(part.partNumber) bytes=\(part.endByte - part.startByte + 1) session=\(sessionID)"
        )

        while true {
            guard let descriptor = await registry.descriptor(for: part.partNumber) else {
                videoDiaryUploadLog("partUpload: missing descriptor part=\(part.partNumber) session=\(sessionID)")
                throw VideoMultipartUploadError.uploadPartHTTP(status: -1, partNumber: part.partNumber)
            }

            let data = try readPartBytes(fileURL: fileURL, part: descriptor)

            do {
                let etag = try await putToPresignedURL(
                    urlString: descriptor.presignedUrl,
                    body: data,
                    partNumber: part.partNumber,
                    session: session
                )
                videoDiaryUploadLog("partUpload: PUT OK part=\(part.partNumber) etagLen=\(etag.count) session=\(sessionID)")
                return etag
            } catch let VideoMultipartUploadError.uploadPartHTTP(status, _) where status == 403 || status == 401 {
                guard refreshCount < maxRefresh else {
                    videoDiaryUploadLog("partUpload: refresh exhausted part=\(part.partNumber) HTTP \(status) session=\(sessionID)")
                    throw VideoMultipartUploadError.uploadPartHTTP(status: status, partNumber: part.partNumber)
                }
                videoDiaryUploadLog(
                    "partUpload: presigned URL rejected HTTP \(status), refresh attempt \(refreshCount + 1)/\(maxRefresh) part=\(part.partNumber) session=\(sessionID)"
                )
                let refreshed = try await apiClient.refreshURLs(
                    body: VideoUploadRefreshURLsRequestBody(id: sessionID, partNumbers: [part.partNumber])
                )
                await registry.applyRefresh(refreshed)
                refreshCount += 1
            } catch {
                videoDiaryUploadLog("partUpload: FAILED part=\(part.partNumber) session=\(sessionID) \(error.localizedDescription)")
                throw error
            }
        }
    }

    private static func putToPresignedURL(
        urlString: String,
        body: Data,
        partNumber: Int,
        session: URLSession
    ) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw VideoMultipartUploadError.uploadPartHTTP(status: -2, partNumber: partNumber)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = body
        let (bodyData, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            videoDiaryUploadLog("presignedPUT: no HTTP response part=\(partNumber)")
            throw VideoMultipartUploadError.uploadPartHTTP(status: -1, partNumber: partNumber)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            videoDiaryUploadLog("presignedPUT: HTTP \(http.statusCode) part=\(partNumber) urlHost=\(url.host ?? "?")")
            throw VideoMultipartUploadError.uploadPartHTTP(status: http.statusCode, partNumber: partNumber)
        }
        videoDiaryUploadLog(
            "presignedPUT: HTTP \(http.statusCode) part=\(partNumber) uploadedBytes=\(bodyData.count) urlHost=\(url.host ?? "?")"
        )
        let raw =
            http.value(forHTTPHeaderField: "ETag")
            ?? http.value(forHTTPHeaderField: "Etag")
        guard let raw, !raw.isEmpty else {
            throw VideoMultipartUploadError.missingETag(partNumber: partNumber)
        }
        return raw
    }

    private static func readPartBytes(fileURL: URL, part: VideoUploadPartDescriptor) throws -> Data {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        try handle.seek(toOffset: UInt64(part.startByte))
        let byteCount = Int(part.endByte - part.startByte + 1)
        let data = handle.readData(ofLength: byteCount)
        guard data.count == byteCount else {
            throw VideoMultipartUploadError.unexpectedReadSize(expected: byteCount, actual: data.count)
        }
        return data
    }

    private func fileByteSize(at url: URL) throws -> Int64 {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        guard let n = values.fileSize else { throw VideoMultipartUploadError.fileNotReadable }
        return Int64(n)
    }

    private func loadDurationSeconds(fileURL: URL) async -> Double {
        let asset = AVURLAsset(url: fileURL)
        do {
            let duration = try await asset.load(.duration)
            let s = CMTimeGetSeconds(duration)
            return s.isFinite && s > 0 ? s : 0
        } catch {
            return 0
        }
    }

    private func loadVideoDimensions(
        fileURL: URL,
        fallback: (width: Int, height: Int)
    ) async -> (width: Int, height: Int) {
        let asset = AVURLAsset(url: fileURL)
        do {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let track = tracks.first else { return fallback }
            let size = try await track.load(.naturalSize)
            let w = Int(size.width.rounded())
            let h = Int(size.height.rounded())
            if w > 0, h > 0 { return (w, h) }
        } catch { }
        return fallback
    }

    /// MIME type of the on-disk video file for the **stored object** (initiate JSON field `contentType`), not the initiate HTTP request.
    private static func mimeTypeForUploadedVideoFile(at url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "mp4", "m4v":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        default:
            return "application/octet-stream"
        }
    }
}

extension VideoMultipartUploadService {
    /// Builds upload settings from the same `beginVideoDiary` body as recording: top-level `activityId` and `participantId`. API base and auth come from the app (not the web message).
    static func uploadConfiguration(
        fromMessageBody messageBody: [String: Any],
        apiBaseURL: URL,
        authorizationHeaderValue: String?
    ) -> VideoDiary.VideoUploadConfiguration? {
        guard let activityId = VideoDiaryMessageParsing.string(from: messageBody["activityId"]),
              let participantId = VideoDiaryMessageParsing.string(from: messageBody["participantId"]) else {
            return nil
        }
        return VideoDiary.VideoUploadConfiguration(
            apiBaseURL: apiBaseURL,
            participantId: participantId,
            activityId: activityId,
            authorizationHeaderValue: authorizationHeaderValue
        )
    }
}

// MARK: - Logging

private func videoDiaryUploadLog(_ message: String) {
    printDebug("[VideoDiaryUpload] \(message)")
}
