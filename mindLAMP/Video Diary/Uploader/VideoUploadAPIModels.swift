// mindLAMP

import Foundation

// MARK: - Initiate

struct VideoUploadInitiateRequestBody: Encodable, Sendable {
    var activityId: String
    var fileSizeBytes: Int64
    var contentType: String
    var metadata: VideoUploadMetadataPayload
}

struct VideoUploadMetadataPayload: Encodable, Sendable {
    var codec: String
    var bitrate: Int
    var durationSeconds: Double
    var frameRate: Int
    var height: Int
    var width: Int
}

struct VideoUploadInitiateResponse: Decodable, Sendable {
    var uploadId: String
    var parts: [VideoUploadPartDescriptor]
    var expiresAt: TimeInterval
}

struct VideoUploadPartDescriptor: Codable, Sendable, Hashable {
    var partNumber: Int
    var startByte: Int64
    var endByte: Int64
    var presignedUrl: String
}

// MARK: - Complete

struct VideoUploadCompleteRequestBody: Encodable, Sendable {
    var uploadId: String
    var parts: [VideoUploadCompletedPartPayload]
}

struct VideoUploadCompletedPartPayload: Encodable, Sendable {
    var partNumber: Int
    var etag: String
}

struct VideoUploadCompleteResponse: Decodable, Sendable {
    var status: String
    var sha256: String
}

// MARK: - Refresh URLs

struct VideoUploadRefreshURLsRequestBody: Encodable, Sendable {
    var uploadId: String
    var partNumbers: [Int]
}

struct VideoUploadRefreshURLsResponse: Decodable, Sendable {
    var parts: [VideoUploadPartDescriptor]
    var expiresAt: TimeInterval
}

// MARK: - Abort

struct VideoUploadAbortRequestBody: Encodable, Sendable {
    var uploadId: String
}
