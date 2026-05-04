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
    /// Present after a successful **initiate** call; tracks session `id`, part layout, and finished part ETags.
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
struct VideoDiaryMultipartProgress: Equatable, Sendable {
    var id: String
    var expiresAt: TimeInterval
    var partDescriptors: [VideoUploadPartDescriptor]
    var completedPartETags: [Int: String]

    init(
        id: String,
        expiresAt: TimeInterval,
        partDescriptors: [VideoUploadPartDescriptor],
        completedPartETags: [Int: String]
    ) {
        self.id = id
        self.expiresAt = expiresAt
        self.partDescriptors = partDescriptors
        self.completedPartETags = completedPartETags
    }
}

extension VideoDiaryMultipartProgress: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case uploadId
        case expiresAt
        case partDescriptors
        case completedPartETags
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let newId = try c.decodeIfPresent(String.self, forKey: .id) {
            self.id = newId
        } else if let legacy = try c.decodeIfPresent(String.self, forKey: .uploadId) {
            self.id = legacy
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: c.codingPath,
                    debugDescription: "Expected \"id\" or legacy \"uploadId\" for multipart session."
                )
            )
        }
        expiresAt = try c.decode(TimeInterval.self, forKey: .expiresAt)
        partDescriptors = try c.decode([VideoUploadPartDescriptor].self, forKey: .partDescriptors)
        completedPartETags = try c.decode([Int: String].self, forKey: .completedPartETags)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(expiresAt, forKey: .expiresAt)
        try c.encode(partDescriptors, forKey: .partDescriptors)
        try c.encode(completedPartETags, forKey: .completedPartETags)
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
