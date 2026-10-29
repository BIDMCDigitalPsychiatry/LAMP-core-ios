import COpenZL
import Foundation

/// Compresses and decodes frames with the vendored OpenZL shim (`lamp_ozl.h`).
public enum OpenZLCodec {
    /// The `codec` field value.
    public static let codecName = "openzl"

    /// The pinned OpenZL format version, sent as `codec_format_version`.
    public static var formatVersion: Int { Int(LAMP_OZL_FORMAT_VERSION) }

    /// The largest decompressed frame this decoder allocates for (66,000 records).
    static let maxDecodedBytes = FramePartitioner.maxRecordsPerFrame * AccelRecordPacker.recordSize

    /// Compresses packed records (a non-empty multiple of 20 bytes).
    public static func compress(_ packed: Data) throws -> Data {
        guard !packed.isEmpty, packed.count % AccelRecordPacker.recordSize == 0 else {
            throw SensorStreamError.invalidInput("packed size \(packed.count) isn't a non-zero multiple of 20")
        }
        var output = Data(count: lamp_ozl_compress_bound(packed.count))
        let capacity = output.count
        let written = packed.withUnsafeBytes { src in
            output.withUnsafeMutableBytes { dst in
                lamp_ozl_compress_accel(src.baseAddress, src.count, dst.baseAddress, capacity)
            }
        }
        guard written > 0 else { throw SensorStreamError.openZL(code: written) }
        output.count = Int(written)
        return output
    }

    /// Decompresses a frame that has exactly one output.
    public static func decompress(_ blob: Data) throws -> Data {
        guard !blob.isEmpty else { throw SensorStreamError.invalidInput("empty frame") }
        let size = blob.withUnsafeBytes { lamp_ozl_decompressed_size($0.baseAddress, $0.count) }
        guard size >= 0 else { throw SensorStreamError.openZL(code: size) }
        guard size <= maxDecodedBytes else {
            throw SensorStreamError.invalidInput("frame declares \(size) bytes, more than \(maxDecodedBytes)")
        }
        // Allocate at least one byte so the shim never sees a NULL destination.
        var output = Data(count: max(Int(size), 1))
        let capacity = output.count
        let written = blob.withUnsafeBytes { src in
            output.withUnsafeMutableBytes { dst in
                lamp_ozl_decompress(src.baseAddress, src.count, dst.baseAddress, capacity)
            }
        }
        if written == Int64(LAMP_OZL_ERR_FORMAT) { throw SensorStreamError.notSingleOutput }
        guard written >= 0 else { throw SensorStreamError.openZL(code: written) }
        output.count = Int(written)
        return output
    }

    /// Reads a frame's OpenZL format version.
    public static func frameFormatVersion(_ blob: Data) throws -> Int {
        guard !blob.isEmpty else { throw SensorStreamError.invalidInput("empty frame") }
        let version = blob.withUnsafeBytes { lamp_ozl_frame_format_version($0.baseAddress, $0.count) }
        guard version >= 0 else { throw SensorStreamError.openZL(code: version) }
        return Int(version)
    }

    /// Decodes a frame and runs the contract's five decoder checks in order:
    /// one output, length multiple of 20, record count, format version, and
    /// first and last timestamps.
    public static func decode(_ blob: Data, sampleCount: Int, codecFormatVersion: Int,
                              startTimestamp: Int64, endTimestamp: Int64) throws -> [AccelRecord] {
        let raw = try decompress(blob)                                            // check 1
        guard raw.count % AccelRecordPacker.recordSize == 0 else {                // check 2
            throw SensorStreamError.lengthNotMultipleOfRecordSize(raw.count)
        }
        let count = raw.count / AccelRecordPacker.recordSize
        guard count == sampleCount else {                                         // check 3
            throw SensorStreamError.sampleCountMismatch(expected: sampleCount, actual: count)
        }
        let version = try frameFormatVersion(blob)
        guard version == codecFormatVersion else {                                // check 4
            throw SensorStreamError.formatVersionMismatch(expected: codecFormatVersion, actual: version)
        }
        let records = AccelRecordPacker.unpack(raw)
        let first = records.first?.timestamp ?? Int64.min
        let last = records.last?.timestamp ?? Int64.min
        guard first == startTimestamp, last == endTimestamp else {                // check 5
            throw SensorStreamError.timestampMismatch(expectedStart: startTimestamp, expectedEnd: endTimestamp,
                                                      actualStart: first, actualEnd: last)
        }
        return records
    }
}
