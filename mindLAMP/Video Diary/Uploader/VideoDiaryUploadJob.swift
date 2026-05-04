// mindLAMP
//
// Persistent upload queue models: one JSON file per job plus a small queue index.

import Foundation

// MARK: - Job

/// One staged video file and its multipart progress; survives process death between parts.
struct VideoDiaryUploadJob: Codable, Equatable, Sendable {
    enum State: String, Codable, Sendable {
        case pending
        case uploading
        /// Terminal failure (policy: keep file + metadata for support / optional manual retry).
        case failed
    }

    var id: UUID
    var createdAt: Date
    var state: State
    /// Filename within the staging directory (not a full path), e.g. `"UUID.mov"`.
    var localVideoFileName: String
    var recordingConfiguration: VideoDiary.RecordingConfiguration
    /// Control-plane API base URL string (`LampURL.videoUploadServiceBaseURLString` at enqueue time).
    var apiBaseURLString: String
    var participantId: String
    var activityId: String
    var policy: VideoDiaryUploadPolicy
    /// Present after a successful **initiate** call; tracks `uploadId`, part layout, and finished part ETags.
    var multipart: VideoDiaryMultipartProgress?
    var lastErrorDescription: String?

    init(
        id: UUID,
        createdAt: Date,
        state: State,
        localVideoFileName: String,
        recordingConfiguration: VideoDiary.RecordingConfiguration,
        apiBaseURLString: String,
        participantId: String,
        activityId: String,
        policy: VideoDiaryUploadPolicy,
        multipart: VideoDiaryMultipartProgress? = nil,
        lastErrorDescription: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.state = state
        self.localVideoFileName = localVideoFileName
        self.recordingConfiguration = recordingConfiguration
        self.apiBaseURLString = apiBaseURLString
        self.participantId = participantId
        self.activityId = activityId
        self.policy = policy
        self.multipart = multipart
        self.lastErrorDescription = lastErrorDescription
    }
}

/// Snapshot of server multipart session needed to PUT remaining parts and call **complete**.
/// `completedPartETags` keys are 1-based part numbers matching the API.
struct VideoDiaryMultipartProgress: Codable, Equatable, Sendable {
    var uploadId: String
    var expiresAt: TimeInterval
    var partDescriptors: [VideoUploadPartDescriptor]
    var completedPartETags: [Int: String]

    init(
        uploadId: String,
        expiresAt: TimeInterval,
        partDescriptors: [VideoUploadPartDescriptor],
        completedPartETags: [Int: String]
    ) {
        self.uploadId = uploadId
        self.expiresAt = expiresAt
        self.partDescriptors = partDescriptors
        self.completedPartETags = completedPartETags
    }
}

// MARK: - Queue index

/// FIFO list of job ids; jobs not listed here are orphans and ignored until reconciliation (future).
struct VideoDiaryUploadQueueIndex: Codable, Equatable, Sendable {
    var orderedJobIds: [UUID]

    init(orderedJobIds: [UUID]) {
        self.orderedJobIds = orderedJobIds
    }

    static let empty = VideoDiaryUploadQueueIndex(orderedJobIds: [])
}

// MARK: - Live API configuration

extension VideoDiaryUploadJob {
    /// Builds the control-plane config using **current** auth (header is not stored on the job).
    func makeUploadConfiguration(authorizationHeaderValue: String?) -> VideoDiary.VideoUploadConfiguration? {
        guard let base = URL(string: apiBaseURLString) else { return nil }
        return VideoDiary.VideoUploadConfiguration(
            apiBaseURL: base,
            participantId: participantId,
            activityId: activityId,
            authorizationHeaderValue: authorizationHeaderValue
        )
    }
}
