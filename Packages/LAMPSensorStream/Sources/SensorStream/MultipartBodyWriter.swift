import Foundation

/// A multipart body written to disk for `URLSession.uploadTask(with:fromFile:)`.
public struct MultipartBody: Equatable {
    public let boundary: String
    /// The `Content-Type` header value, including the boundary.
    public let contentType: String
    public let fileURL: URL
    public let byteLength: Int
}

/// Writes `multipart/form-data` upload bodies: the text fields first, in
/// contract order, then the `frame` file part.
public enum MultipartBodyWriter {
    /// The text fields, in the order they're written.
    public static let fieldNames: [String] = []
    /// The name of the file part.
    public static let filePartName = "frame"

    /// Returns the text fields for `metadata`, in contract order.
    public static func fields(for metadata: FrameMetadata) -> [(name: String, value: String)] {
        []
    }

    /// Returns a new random boundary.
    public static func makeBoundary() -> String {
        ""
    }

    /// Writes the body for `frame` to `url`, replacing any existing file.
    public static func write(metadata: FrameMetadata, frame: Data, to url: URL,
                             boundary: String = MultipartBodyWriter.makeBoundary()) throws -> MultipartBody {
        throw SensorStreamError.notImplemented
    }
}
