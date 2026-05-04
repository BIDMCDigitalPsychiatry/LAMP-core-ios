// mindLAMP
//
// Serializes background video uploads: one active transfer at a time, JSON checkpointing, Wi‑Fi policy, and logout cleanup.

import Foundation

// MARK: - Delegate (UI / web bridge)

/// Receives the **final** outcome of a job (after the file is removed from disk on success).
@MainActor
protocol VideoDiaryUploadCoordinatorDelegate: AnyObject {
    func videoDiaryUploadDidFinish(jobId: UUID, result: Swift.Result<VideoUploadCompleteResponse, Error>)
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
        await scheduleDrainQueue()
    }

    /// Drops queued files/metadata and cancels in-memory drain (best-effort). Call on logout.
    func cancelAllDueToLogout() async {
        try? jobStore.removeAllUploadData()
        isDraining = false
    }

    /// Entry point for path changes and post-login kicks.
    func scheduleDrainQueue() async {
        guard !isDraining else { return }
        isDraining = true
        defer { isDraining = false }
        await drainQueueLoop()
    }

    // MARK: Persistence hops (called from `VideoMultipartUploadService` callbacks)

    /// Checkpoint after **initiate** so we never lose `uploadId` if the app terminates before the first `PUT`.
    func persistInitiatedSnapshot(jobId: UUID, snapshot: VideoDiaryMultipartProgress) async throws {
        var job = try jobStore.loadJob(id: jobId)
        job.multipart = snapshot
        try jobStore.saveJob(job)
    }

    /// Checkpoint each finished S3 part so retries skip completed byte ranges.
    func persistPartETag(jobId: UUID, partNumber: Int, etag: String) async throws {
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
            guard let headId = index.orderedJobIds.first else { return }

            guard var job = try? jobStore.loadJob(id: headId) else {
                try? removeHeadInvalidJobId(headId)
                continue
            }

            guard pathMonitor.allowsUpload(with: job.policy) else { return }

            if job.state == .pending {
                job.state = .uploading
                try? jobStore.saveJob(job)
            }

            guard let uploadConfiguration = job.makeUploadConfiguration(
                authorizationHeaderValue: LampURL.videoUploadServiceAuthorizationHeader
            ) else {
                await failJobTerminal(jobId: job.id, message: "Invalid video upload API base URL in job.")
                continue
            }

            let fileURL: URL
            do {
                fileURL = try jobStore.videoFileURL(fileName: job.localVideoFileName)
            } catch {
                try? removeHeadInvalidJobId(job.id)
                continue
            }

            let service = VideoMultipartUploadService(configuration: uploadConfiguration)
            let captureJobId = job.id

            do {
                let response = try await service.uploadResumable(
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
                await notifySuccess(jobId: job.id, response: response)
            } catch {
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

    private func notifySuccess(jobId: UUID, response: VideoUploadCompleteResponse) async {
        let result: Swift.Result<VideoUploadCompleteResponse, Error> = .success(response)
        // Snapshot delegate on the actor; `MainActor.run` must not touch actor-isolated storage directly.
        let callbackTarget = self.delegate
        await MainActor.run {
            callbackTarget?.videoDiaryUploadDidFinish(jobId: jobId, result: result)
        }
    }

    private func notifyFailure(jobId: UUID, error: Error) async {
        let callbackTarget = self.delegate
        await MainActor.run {
            callbackTarget?.videoDiaryUploadDidFinish(jobId: jobId, result: .failure(error))
        }
    }
}
