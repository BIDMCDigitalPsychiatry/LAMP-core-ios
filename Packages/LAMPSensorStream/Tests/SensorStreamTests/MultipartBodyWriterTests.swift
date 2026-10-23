import XCTest
@testable import SensorStream

final class MultipartBodyWriterTests: XCTestCase {
    static let contractFields = ["sensor_spec", "start_timestamp", "end_timestamp", "sample_count", "codec",
                                 "codec_format_version", "platform", "unit", "sha256"]

    func testFieldNamesAndOrderMatchContract() throws {
        XCTAssertEqual(MultipartBodyWriter.fieldNames, Self.contractFields)
        XCTAssertEqual(MultipartBodyWriter.filePartName, "frame")
        let meta = try Fixtures.meta("frame.openzl")
        let fields = MultipartBodyWriter.fields(for: meta)
        XCTAssertEqual(fields.map(\.name), Self.contractFields)
        XCTAssertEqual(fields.map(\.value), ["lamp.accelerometer50hz", "1790000100000", "1790000109980", "500", "openzl",
                                             "24", "android", "m/s^2", meta.sha256])
    }

    func testBoundariesAreUniqueAndSafe() {
        let a = MultipartBodyWriter.makeBoundary()
        let b = MultipartBodyWriter.makeBoundary()
        XCTAssertNotEqual(a, b)
        XCTAssertGreaterThanOrEqual(a.count, 20)
        XCTAssertLessThanOrEqual(a.count, 70)
        XCTAssertTrue(a.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") })
    }

    func testBodyHasTextFieldsBeforeFramePart() throws {
        let meta = try Fixtures.meta("frame.openzl")
        let frame = try Fixtures.data("frame.openzl")
        let url = try Fixtures.temporaryDirectory().appendingPathComponent("body.multipart")
        let body = try MultipartBodyWriter.write(metadata: meta, frame: frame, to: url, boundary: "lamp-test-boundary")
        XCTAssertEqual(body.boundary, "lamp-test-boundary")
        XCTAssertEqual(body.contentType, "multipart/form-data; boundary=lamp-test-boundary")
        XCTAssertEqual(body.fileURL, url)

        let bytes = try Data(contentsOf: url)
        XCTAssertEqual(body.byteLength, bytes.count)
        let parts = try Self.parse(bytes, boundary: body.boundary)
        XCTAssertEqual(parts.map(\.name), Self.contractFields + ["frame"])
        for (part, field) in zip(parts, MultipartBodyWriter.fields(for: meta)) {
            XCTAssertEqual(String(data: part.body, encoding: .utf8), field.value)
            XCTAssertNil(part.filename)
        }
        let filePart = try XCTUnwrap(parts.last)
        XCTAssertEqual(filePart.body, frame)
        XCTAssertNotNil(filePart.filename)
        XCTAssertEqual(filePart.contentType, "application/octet-stream")
        let closing = Data("\r\n--lamp-test-boundary--\r\n".utf8)
        XCTAssertEqual(bytes.suffix(closing.count), closing)
    }

    func testWriteReplacesExistingFile() throws {
        let meta = try Fixtures.meta("frame_single.openzl")
        let url = try Fixtures.temporaryDirectory().appendingPathComponent("body.multipart")
        try Data(repeating: 0xFF, count: 100_000).write(to: url)
        let body = try MultipartBodyWriter.write(metadata: meta, frame: try Fixtures.data("frame_single.openzl"), to: url)
        XCTAssertEqual(try Data(contentsOf: url).count, body.byteLength)
        XCTAssertLessThan(body.byteLength, 100_000)
    }

    struct Part {
        var name: String
        var filename: String?
        var contentType: String?
        var body: Data
    }

    /// A strict RFC 7578 parser for the test: CRLF line endings, one boundary.
    static func parse(_ data: Data, boundary: String) throws -> [Part] {
        let delimiter = Data("--\(boundary)".utf8)
        let crlf = Data("\r\n".utf8)
        var parts: [Part] = []
        var cursor = data.startIndex
        guard data[cursor...].starts(with: delimiter) else { throw SensorStreamError.invalidInput("no opening boundary") }
        cursor += delimiter.count
        while true {
            if data[cursor...].starts(with: Data("--".utf8)) { break }
            guard data[cursor...].starts(with: crlf) else { throw SensorStreamError.invalidInput("bad boundary line") }
            cursor += crlf.count
            let headerEnd = try XCTUnwrap(data.range(of: Data("\r\n\r\n".utf8), in: cursor..<data.endIndex))
            let headers = String(decoding: data[cursor..<headerEnd.lowerBound], as: UTF8.self).components(separatedBy: "\r\n")
            cursor = headerEnd.upperBound
            let next = try XCTUnwrap(data.range(of: crlf + delimiter, in: cursor..<data.endIndex))
            var part = Part(name: "", body: Data(data[cursor..<next.lowerBound]))
            for header in headers {
                if header.hasPrefix("Content-Disposition: form-data; ") {
                    for item in header.dropFirst("Content-Disposition: form-data; ".count).components(separatedBy: "; ") {
                        let kv = item.split(separator: "=", maxSplits: 1).map(String.init)
                        let value = kv[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                        if kv[0] == "name" { part.name = value }
                        if kv[0] == "filename" { part.filename = value }
                    }
                } else if header.hasPrefix("Content-Type: ") {
                    part.contentType = String(header.dropFirst("Content-Type: ".count))
                } else {
                    throw SensorStreamError.invalidInput("unexpected header \(header)")
                }
            }
            parts.append(part)
            cursor = next.upperBound
        }
        return parts
    }
}
