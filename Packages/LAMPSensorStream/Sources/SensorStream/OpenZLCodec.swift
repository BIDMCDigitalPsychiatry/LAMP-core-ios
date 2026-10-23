import COpenZL
import Foundation

/// Compresses and decodes frames with the vendored OpenZL shim (`lamp_ozl.h`).
public enum OpenZLCodec {
    /// The `codec` field value.
    public static let codecName = "openzl"

    /// The pinned OpenZL format version, sent as `codec_format_version`.
    public static var formatVersion: Int { Int(LAMP_OZL_FORMAT_VERSION) }

    /// Compresses packed records (a non-empty multiple of 20 bytes).
    public static func compress(_ packed: Data) throws -> Data {
        throw SensorStreamError.notImplemented
    }

    /// Decompresses a frame that has exactly one output.
    public static func decompress(_ blob: Data) throws -> Data {
        throw SensorStreamError.notImplemented
    }

    /// Reads a frame's OpenZL format version.
    public static func frameFormatVersion(_ blob: Data) throws -> Int {
        throw SensorStreamError.notImplemented
    }

    /// Decodes a frame and runs the contract's five decoder checks in order.
    public static func decode(_ blob: Data, sampleCount: Int, codecFormatVersion: Int,
                              startTimestamp: Int64, endTimestamp: Int64) throws -> [AccelRecord] {
        throw SensorStreamError.notImplemented
    }
}
