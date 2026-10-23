import XCTest
@testable import SensorStream

/// Writes one produced frame, its multipart body, and its metadata for the
/// Phase D cross-language check (server upload, cortex and raphe decode).
final class ProducedArtifactTests: XCTestCase {
    func testWritesProducedFrameForCrossLanguageCheck() throws {
        let out = FileManager.default.temporaryDirectory.appendingPathComponent("lamp-ios-produced", isDirectory: true)
        try? FileManager.default.removeItem(at: out)
        let store = FrameStore(root: out.appendingPathComponent("store", isDirectory: true))
        let records = try Fixtures.records()
        let sealed = try store.seal(spec: "lamp.accelerometer50hz", frameID: "produced", records: records)
        let frame = try store.data(for: sealed)

        let frameURL = out.appendingPathComponent("frame.openzl")
        try frame.write(to: frameURL)
        let body = try MultipartBodyWriter.write(metadata: sealed.metadata, frame: frame,
                                                 to: out.appendingPathComponent("multipart.body"))
        var meta = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(sealed.metadata)) as? [String: Any])
        meta["content_type"] = body.contentType
        meta["boundary"] = body.boundary
        let metaURL = out.appendingPathComponent("meta.json")
        try JSONSerialization.data(withJSONObject: meta, options: [.prettyPrinted, .sortedKeys]).write(to: metaURL)
        try store.removeAll()

        print("lamp-ios-produced: \(out.path)")
        XCTAssertEqual(sealed.metadata.platform, "ios")
        XCTAssertEqual(sealed.metadata.sampleCount, 500)
        XCTAssertEqual(try OpenZLCodec.decode(Data(contentsOf: frameURL), sampleCount: 500, codecFormatVersion: 24,
                                              startTimestamp: sealed.metadata.startTimestamp,
                                              endTimestamp: sealed.metadata.endTimestamp), records)
        XCTAssertTrue(FileManager.default.fileExists(atPath: body.fileURL.path))
    }
}
