import Foundation

/// Errors that the sensor-stream encoder, decoder, and store throw.
public enum SensorStreamError: Error, Equatable {
    /// The function is a stub.
    case notImplemented
    /// An argument is outside the contract (for example, an empty frame).
    case invalidInput(String)
    /// The OpenZL shim returned a negative error code.
    case openZL(code: Int64)
    /// Decoder check 1: the OpenZL frame doesn't have exactly one output.
    case notSingleOutput
    /// Decoder check 2: the decompressed length isn't a multiple of 20.
    case lengthNotMultipleOfRecordSize(Int)
    /// Decoder check 3: the record count doesn't equal `sample_count`.
    case sampleCountMismatch(expected: Int, actual: Int)
    /// Decoder check 4: the frame's format version doesn't equal `codec_format_version`.
    case formatVersionMismatch(expected: Int, actual: Int)
    /// Decoder check 5: the first or last timestamp doesn't match the metadata.
    case timestampMismatch(expectedStart: Int64, expectedEnd: Int64, actualStart: Int64, actualEnd: Int64)
}
