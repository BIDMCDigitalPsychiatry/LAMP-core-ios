// mindLAMP
//
// Serializes background video uploads: one active transfer at a time, JSON checkpointing, Wi‑Fi policy, and logout cleanup.

import Foundation

// MARK: - Delegate (UI / web bridge)

/// Receives the **final** outcome of a job (after the file is removed from disk on success).
@MainActor
protocol VideoDiaryUploadCoordinatorDelegate: AnyObject {
    func videoDiaryUploadDidFinish(jobId: UUID, result: Swift.Result<Void, Error>)
}

// MARK: - Coordinator

/// Owns the FIFO queue, applies network policy, and checkpoints each multipart part to disk.
///
/// **Why `actor`:** Serializes enqueue/drain/checkpoint state without ad‑hoc locks. You could instead use a `final class`
/// plus a private serial `DispatchQueue` for the same serialization; `actor` fits async call sites (`await enqueue`, …).
actor VideoDiaryUploadCoordinator {
    static let shared = VideoDiaryUploadCoordinator()

    /// UI delegate (e.g. `HomeViewController`) — completion only, no progress UI by design.
    weak var delegate: VideoDiaryUploadCoordinatorDelegate?

    private let jobStore: VideoDiaryUploadJobStoring
    private let pathMonitor: VideoDiaryNetworkPathMonitoring
    private var isDraining = false

    /// - Parameters:
    ///   - jobStore: inject a mock in unit tests.
    ///   - pathMonitor: inject a fake path monitor to bypass `NWPathMonitor`.
    init(
        jobStore: VideoDiaryUploadJobStoring? = nil,
        pathMonitor: VideoDiaryNetworkPathMonitoring? = nil
    ) {
        self.jobStore = jobStore ?? FileVideoDiaryUploadJobStore()
        self.pathMonitor = pathMonitor ?? VideoDiarySystemNetworkPathMonitor()
        self.pathMonitor.onPathsMayHaveChanged = {
            Task { await VideoDiaryUploadCoordinator.shared.scheduleDrainQueue() }
        }
        self.pathMonitor.start()
        Task { await VideoDiaryUploadCoordinator.shared.scheduleDrainQueue() }
    }

    // MARK: API

    /// Copies the recording into app storage and appends a **pending** job. Upload starts when policy + connectivity allow.
    func registerDelegate(_ delegate: VideoDiaryUploadCoordinatorDelegate?) {
        self.delegate = delegate
    }

    func enqueue(
        sourceVideoFileURL: URL,
        recordingConfiguration: VideoDiary.RecordingConfiguration,
        apiBaseURL: URL,
        participantId: String,
        activityId: String,
        policy: VideoDiaryUploadPolicy = .default
    ) async throws {
        let id = UUID()
        let fileName = try jobStore.stageVideoFile(from: sourceVideoFileURL, jobId: id)
        let job = VideoDiaryUploadJob(
            id: id,
            createdAt: Date(),
            state: .pending,
            localVideoFileName: fileName,
            recordingConfiguration: recordingConfiguration,
            apiBaseURLString: apiBaseURL.absoluteString,
            participantId: participantId,
            activityId: activityId,
            policy: policy
        )
        try jobStore.saveJob(job)
        var index = try jobStore.loadQueueIndex()
        index.orderedJobIds.append(id)
        try jobStore.saveQueueIndex(index)
        videoDiaryUploadLog(
            "enqueue: jobId=\(id) activityId=\(activityId) participantId=\(participantId) stagedFile=\(fileName) apiBase=\(apiBaseURL.absoluteString) queueDepth=\(index.orderedJobIds.count)"
        )
        await scheduleDrainQueue()
    }

    /// Drops queued files/metadata and cancels in-memory drain (best-effort). Call on logout.
    func cancelAllDueToLogout() async {
        videoDiaryUploadLog("cancelAllDueToLogout: clearing queue and uploads")
        try? jobStore.removeAllUploadData()
        isDraining = false
    }

    /// Entry point for path changes and post-login kicks.
    func scheduleDrainQueue() async {
        guard !isDraining else {
            videoDiaryUploadLog("scheduleDrain: already draining, skip")
            return
        }
        isDraining = true
        defer { isDraining = false }
        videoDiaryUploadLog("scheduleDrain: starting drain loop")
        await drainQueueLoop()
    }

    // MARK: Persistence hops (called from `VideoMultipartUploadService` callbacks)

    /// Checkpoint after **initiate** so we never lose the multipart session `id` if the app terminates before the first `PUT`.
    func persistInitiatedSnapshot(jobId: UUID, snapshot: VideoDiaryMultipartProgress) async throws {
        videoDiaryUploadLog(
            "persist: initiated checkpoint jobId=\(jobId) session=\(snapshot.id) parts=\(snapshot.partDescriptors.count)"
        )
        var job = try jobStore.loadJob(id: jobId)
        job.multipart = snapshot
        try jobStore.saveJob(job)
    }

    /// Checkpoint each finished S3 part so retries skip completed byte ranges.
    func persistPartETag(jobId: UUID, partNumber: Int, etag: String) async throws {
        videoDiaryUploadLog("persist: part ETag jobId=\(jobId) part=\(partNumber) etagLen=\(etag.count)")
        var job = try jobStore.loadJob(id: jobId)
        guard var multi = job.multipart else { return }
        multi.completedPartETags[partNumber] = etag
        job.multipart = multi
        try jobStore.saveJob(job)
    }

    // MARK: - Drain

    private func drainQueueLoop() async {
        while true {
            let index = (try? jobStore.loadQueueIndex()) ?? .empty
            guard let headId = index.orderedJobIds.first else {
                videoDiaryUploadLog("drain: queue empty, exit")
                return
            }

            guard var job = try? jobStore.loadJob(id: headId) else {
                videoDiaryUploadLog("drain: missing job file for id=\(headId), removing head")
                try? removeHeadInvalidJobId(headId)
                continue
            }

            guard pathMonitor.allowsUpload(with: job.policy) else {
                videoDiaryUploadLog("drain: blocked by network policy jobId=\(job.id) state=\(job.state)")
                return
            }

            if job.state == .pending {
                job.state = .uploading
                try? jobStore.saveJob(job)
            }

            guard let uploadConfiguration = job.makeUploadConfiguration(
                authorizationHeaderValue: LampURL.videoUploadServiceAuthorizationHeader
            ) else {
                videoDiaryUploadLog("drain: invalid API base URL jobId=\(job.id)")
                await failJobTerminal(jobId: job.id, message: "Invalid video upload API base URL in job.")
                continue
            }

            let fileURL: URL
            do {
                fileURL = try jobStore.videoFileURL(fileName: job.localVideoFileName)
            } catch {
                videoDiaryUploadLog("drain: missing staged video jobId=\(job.id) file=\(job.localVideoFileName)")
                try? removeHeadInvalidJobId(job.id)
                continue
            }

            videoDiaryUploadLog(
                "drain: BEGIN upload jobId=\(job.id) activityId=\(job.activityId) resume=\(job.multipart != nil) file=\(job.localVideoFileName)"
            )
            let service = VideoMultipartUploadService(configuration: uploadConfiguration)
            let captureJobId = job.id

            do {
                try await service.uploadResumable(
                    fileURL: fileURL,
                    recordingConfiguration: job.recordingConfiguration,
                    activityId: job.activityId,
                    resume: job.multipart,
                    shouldAbortRemoteSessionOnFailure: false,
                    progress: { _ in },
                    onInitiated: { snapshot in
                        try await VideoDiaryUploadCoordinator.shared.persistInitiatedSnapshot(jobId: captureJobId, snapshot: snapshot)
                    },
                    onPartUploaded: { partNumber, etag in
                        try await VideoDiaryUploadCoordinator.shared.persistPartETag(jobId: captureJobId, partNumber: partNumber, etag: etag)
                    }
                )

                try jobStore.removeArtifacts(jobId: job.id, videoFileName: job.localVideoFileName)
                try dequeueHead(jobId: job.id)
                videoDiaryUploadLog("drain: SUCCESS jobId=\(job.id), notifying delegate")
                await notifySuccess(jobId: job.id)
            } catch {
                videoDiaryUploadLog("drain: FAILED jobId=\(captureJobId) \(error.localizedDescription) — will retry when drain runs again")
                await handleUploadError(jobId: captureJobId, error: error)
                return
            }
        }
    }

    private func handleUploadError(jobId: UUID, error: Error) async {
        guard var job = try? jobStore.loadJob(id: jobId) else { return }
        job.state = .pending
        job.lastErrorDescription = error.localizedDescription
        try? jobStore.saveJob(job)
        videoDiaryUploadLog("handleUploadError: jobId=\(jobId) reset to pending lastError=\(error.localizedDescription)")
    }

    private func failJobTerminal(jobId: UUID, message: String) async {
        guard var job = try? jobStore.loadJob(id: jobId) else {
            try? removeHeadInvalidJobId(jobId)
            return
        }
        job.state = .failed
        job.lastErrorDescription = message
        try? jobStore.saveJob(job)
        try? jobStore.removeArtifacts(jobId: jobId, videoFileName: job.localVideoFileName)
        try? dequeueHead(jobId: jobId)
        videoDiaryUploadLog("failJobTerminal: jobId=\(jobId) message=\(message)")
        let err = NSError(domain: "VideoDiaryUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        await notifyFailure(jobId: jobId, error: err)
    }

    private func dequeueHead(jobId: UUID) throws {
        var index = try jobStore.loadQueueIndex()
        if index.orderedJobIds.first == jobId {
            index.orderedJobIds.removeFirst()
        } else {
            index.orderedJobIds.removeAll { $0 == jobId }
        }
        try jobStore.saveQueueIndex(index)
    }

    private func removeHeadInvalidJobId(_ jobId: UUID) throws {
        var index = try jobStore.loadQueueIndex()
        index.orderedJobIds.removeAll { $0 == jobId }
        try jobStore.saveQueueIndex(index)
    }

    private func notifySuccess(jobId: UUID) async {
        videoDiaryUploadLog("notifySuccess: jobId=\(jobId)")
        let result: Swift.Result<Void, Error> = .success(())
        // Snapshot delegate on the actor; `MainActor.run` must not touch actor-isolated storage directly.
        let callbackTarget = self.delegate
        await MainActor.run {
            callbackTarget?.videoDiaryUploadDidFinish(jobId: jobId, result: result)
        }
    }

    private func notifyFailure(jobId: UUID, error: Error) async {
        videoDiaryUploadLog("notifyFailure: jobId=\(jobId) \(error.localizedDescription)")
        let callbackTarget = self.delegate
        await MainActor.run {
            callbackTarget?.videoDiaryUploadDidFinish(jobId: jobId, result: .failure(error))
        }
    }
}

// MARK: - Logging

private func videoDiaryUploadLog(_ message: String) {
    printDebug("[VideoDiaryUpload] \(message)")
}
