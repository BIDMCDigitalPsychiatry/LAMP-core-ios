import CryptoKit
import Foundation

/// Upload metadata for one sealed frame. The JSON keys match the multipart
/// field names and the server's GridFS metadata.
public struct FrameMetadata: Codable, Equatable {
    /// The only unit the contract allows.
    public static let unit = "m/s^2"

    public var sensorSpec: String
    public var startTimestamp: Int64
    public var endTimestamp: Int64
    public var sampleCount: Int
    public var codec: String
    public var codecFormatVersion: Int
    public var platform: String
    public var unit: String
    public var sha256: String
    public var byteLength: Int

    enum CodingKeys: String, CodingKey {
        case sensorSpec = "sensor_spec"
        case startTimestamp = "start_timestamp"
        case endTimestamp = "end_timestamp"
        case sampleCount = "sample_count"
        case codec
        case codecFormatVersion = "codec_format_version"
        case platform
        case unit
        case sha256
        case byteLength = "byte_length"
    }

    public init(sensorSpec: String, startTimestamp: Int64, endTimestamp: Int64, sampleCount: Int,
                codec: String, codecFormatVersion: Int, platform: String, unit: String = FrameMetadata.unit,
                sha256: String, byteLength: Int) {
        self.sensorSpec = sensorSpec
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.sampleCount = sampleCount
        self.codec = codec
        self.codecFormatVersion = codecFormatVersion
        self.platform = platform
        self.unit = unit
        self.sha256 = sha256
        self.byteLength = byteLength
    }

    /// Builds the OpenZL metadata for stable-sorted records and their compressed bytes.
    public static func make(sensorSpec: String, records: [AccelRecord], compressed: Data,
                            platform: String) -> FrameMetadata {
        FrameMetadata(sensorSpec: sensorSpec,
                      startTimestamp: records.first?.timestamp ?? 0,
                      endTimestamp: records.last?.timestamp ?? 0,
                      sampleCount: records.count,
                      codec: OpenZLCodec.codecName,
                      codecFormatVersion: OpenZLCodec.formatVersion,
                      platform: platform,
                      sha256: sha256Hex(compressed),
                      byteLength: compressed.count)
    }

    /// Returns the lowercase hex SHA-256 digest of `data`.
    public static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
