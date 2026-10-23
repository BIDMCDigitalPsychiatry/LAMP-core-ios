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
    public static let fieldNames: [String] = [
        "sensor_spec", "start_timestamp", "end_timestamp", "sample_count", "codec",
        "codec_format_version", "platform", "unit", "sha256",
    ]
    /// The name of the file part.
    public static let filePartName = "frame"

    /// Returns the text fields for `metadata`, in contract order.
    public static func fields(for metadata: FrameMetadata) -> [(name: String, value: String)] {
        let values = [
            metadata.sensorSpec, String(metadata.startTimestamp), String(metadata.endTimestamp),
            String(metadata.sampleCount), metadata.codec, String(metadata.codecFormatVersion),
            metadata.platform, metadata.unit, metadata.sha256,
        ]
        return Array(zip(fieldNames, values)).map { (name: $0.0, value: $0.1) }
    }

    /// Returns a new random boundary.
    public static func makeBoundary() -> String {
        "lamp-sensor-stream-" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }

    /// Writes the body for `frame` to `url`, replacing any existing file.
    public static func write(metadata: FrameMetadata, frame: Data, to url: URL,
                             boundary: String = MultipartBodyWriter.makeBoundary()) throws -> MultipartBody {
        var body = Data()
        body.reserveCapacity(frame.count + 2_048)
        func append(_ text: String) { body.append(Data(text.utf8)) }

        for field in fields(for: metadata) {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"\(field.name)\"\r\n\r\n")
            append("\(field.value)\r\n")
        }
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(filePartName)\"; "
               + "filename=\"\(metadata.startTimestamp).\(metadata.codec)\"\r\n")
        append("Content-Type: application/octet-stream\r\n\r\n")
        body.append(frame)
        append("\r\n--\(boundary)--\r\n")

        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try body.write(to: url, options: .atomic)
        return MultipartBody(boundary: boundary, contentType: "multipart/form-data; boundary=\(boundary)",
                             fileURL: url, byteLength: body.count)
    }
}
