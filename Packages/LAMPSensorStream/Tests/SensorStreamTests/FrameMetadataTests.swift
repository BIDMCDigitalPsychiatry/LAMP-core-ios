import XCTest
@testable import SensorStream

final class FrameMetadataTests: XCTestCase {
    func testMakeMatchesGoldenMetadataExceptPlatform() throws {
        let blob = try Fixtures.data("frame.openzl")
        let made = FrameMetadata.make(sensorSpec: "lamp.accelerometer50hz", records: try Fixtures.records(),
                                      compressed: blob, platform: "android")
        XCTAssertEqual(made, try Fixtures.meta("frame.openzl"))
    }

    func testSha256IsLowercaseHex() throws {
        let digest = FrameMetadata.sha256Hex(try Fixtures.data("frame_single.openzl"))
        XCTAssertEqual(digest, try Fixtures.meta("frame_single.openzl").sha256)
        XCTAssertEqual(FrameMetadata.sha256Hex(Data()), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    }

    func testJSONUsesContractKeys() throws {
        let meta = try Fixtures.meta("frame.openzl")
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(meta)) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["sensor_spec", "start_timestamp", "end_timestamp", "sample_count", "codec",
                                          "codec_format_version", "platform", "unit", "sha256", "byte_length"])
        XCTAssertEqual(object["unit"] as? String, "m/s^2")
    }
}
