// mindLAMP

import Foundation

// MARK: - Initiate

/// JSON body for `POST .../initiate` (the HTTP request itself is `application/json`).
/// `contentType` is **not** the type of this request; it tells the server the MIME type of the **video object**
/// that will be uploaded in the multipart PUT phase (e.g. S3 object `Content-Type`), alongside size and codec metadata.
struct VideoUploadInitiateRequestBody: Encodable, Sendable {
//    var activityId: String
//    var fileSizeBytes: Int64
    /// MIME type of the file bytes that follow in part uploads (e.g. `video/mp4`), not the initiate POST body.
//    var contentType: String
    var participantId: String
    var metadata: VideoUploadMetadataPayload
}

struct VideoUploadMetadataPayload: Encodable, Sendable {
    var size: Int64
    var codec: String
    var bitrate: Int
    var duration: Double
    var frameRate: Int
    var height: Int
    var width: Int
}

struct VideoUploadInitiateResponse: Decodable, Sendable {
    var id: String
    var parts: [VideoUploadPartDescriptor]
    var expiresAt: TimeInterval

    enum CodingKeys: String, CodingKey {
        case id
        case parts
        case expiresAt
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        parts = try container.decode([VideoUploadPartDescriptor].self, forKey: .parts)

        if let expiresAt = try container.decodeIfPresent(TimeInterval.self, forKey: .expiresAt) {
            self.expiresAt = expiresAt
        } else {
            // New API sends expiration per part; use the latest expiration for registry refresh checks.
            self.expiresAt = parts.map(\.presignedUrlExpiration).max() ?? 0
        }
    }
}

struct VideoUploadInitiatedMetadata: Sendable {
    var participantId: String
    var activityId: String
    var durationSeconds: Double
    var width: Int
    var height: Int
    var fileSizeBytes: Int64
    var mimeType: String
}

struct VideoUploadPartDescriptor: Codable, Sendable, Hashable {
    var partNumber: Int
    var startByte: Int64
    var endByte: Int64
    var method: String?
    var presignedUrl: String
    var presignedUrlExpiration: TimeInterval

    /// Used when merging refresh-url responses that omit byte ranges (see `UploadPartURLRegistry.applyRefresh`).
    init(
        partNumber: Int,
        startByte: Int64,
        endByte: Int64,
        method: String?,
        presignedUrl: String,
        presignedUrlExpiration: TimeInterval
    ) {
        self.partNumber = partNumber
        self.startByte = startByte
        self.endByte = endByte
        self.method = method
        self.presignedUrl = presignedUrl
        self.presignedUrlExpiration = presignedUrlExpiration
    }

    enum CodingKeys: String, CodingKey {
        case partNumber
        case startByte
        case endByte
        case method
        case presignedUrl
        case presignedUrlExpiration
        case byteRange
    }

    enum ByteRangeCodingKeys: String, CodingKey {
        case start
        case end
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        partNumber = try container.decode(Int.self, forKey: .partNumber)
        presignedUrl = try container.decode(String.self, forKey: .presignedUrl)
        method = try container.decodeIfPresent(String.self, forKey: .method)
        presignedUrlExpiration = try container.decodeIfPresent(TimeInterval.self, forKey: .presignedUrlExpiration) ?? 0

        if container.contains(.byteRange) {
            let range = try container.nestedContainer(keyedBy: ByteRangeCodingKeys.self, forKey: .byteRange)
            startByte = try range.decode(Int64.self, forKey: .start)
            endByte = try range.decode(Int64.self, forKey: .end)
        } else {
            startByte = try container.decode(Int64.self, forKey: .startByte)
            endByte = try container.decode(Int64.self, forKey: .endByte)
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(partNumber, forKey: .partNumber)
        try container.encode(startByte, forKey: .startByte)
        try container.encode(endByte, forKey: .endByte)
        try container.encodeIfPresent(method, forKey: .method)
        try container.encode(presignedUrl, forKey: .presignedUrl)
        try container.encode(presignedUrlExpiration, forKey: .presignedUrlExpiration)

        var range = container.nestedContainer(keyedBy: ByteRangeCodingKeys.self, forKey: .byteRange)
        try range.encode(startByte, forKey: .start)
        try range.encode(endByte, forKey: .end)
    }
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

/// `POST .../refresh-urls` body — may omit `byteRange` / `startByte`/`endByte`; merge with
/// the existing `VideoUploadPartDescriptor` from initiate for each `partNumber`.
struct VideoUploadRefreshURLPart: Decodable, Sendable {
    var partNumber: Int
    var method: String?
    var presignedUrl: String
    var presignedUrlExpiration: TimeInterval
}

struct VideoUploadRefreshURLsResponse: Decodable, Sendable {
    var id: String
    var parts: [VideoUploadRefreshURLPart]
    var expiresAt: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case id
        case parts
        case expiresAt
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        parts = try c.decode([VideoUploadRefreshURLPart].self, forKey: .parts)
        expiresAt = try c.decodeIfPresent(TimeInterval.self, forKey: .expiresAt)
    }

    /// Registry refresh deadline: top-level `expiresAt` if the server sends it, else max part URL expiry.
    var resolvedExpiresAt: TimeInterval {
        if let expiresAt { return expiresAt }
        return parts.map(\.presignedUrlExpiration).max() ?? 0
    }
}

// MARK: - Abort

struct VideoUploadAbortRequestBody: Encodable, Sendable {
    var id: String
}
