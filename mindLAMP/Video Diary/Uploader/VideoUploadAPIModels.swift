// mindLAMP

import Foundation

// MARK: - Initiate

/// JSON body for `POST .../initiate` (the HTTP request itself is `application/json`).
/// `contentType` is **not** the type of this request; it tells the server the MIME type of the **video object**
/// that will be uploaded in the multipart PUT phase (e.g. S3 object `Content-Type`), alongside size and codec metadata.
struct VideoUploadInitiateRequestBody: Encodable, Sendable {
    var activityId: String
    var fileSizeBytes: Int64
    /// MIME type of the file bytes that follow in part uploads (e.g. `video/mp4`), not the initiate POST body.
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
    var id: String
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
    var id: String
    var parts: [VideoUploadCompletedPartPayload]
}

struct VideoUploadCompletedPartPayload: Encodable, Sendable {
    var partNumber: Int
    var etag: String
}

// MARK: - Refresh URLs

struct VideoUploadRefreshURLsRequestBody: Encodable, Sendable {
    var id: String
    var partNumbers: [Int]
}

struct VideoUploadRefreshURLsResponse: Decodable, Sendable {
    var parts: [VideoUploadPartDescriptor]
    var expiresAt: TimeInterval
}

// MARK: - Abort

struct VideoUploadAbortRequestBody: Encodable, Sendable {
    var id: String
}
