import XCTest
@testable import SensorStream

final class OpenZLCodecTests: XCTestCase {
    func testFormatVersionIsPinnedTo24() {
        XCTAssertEqual(OpenZLCodec.formatVersion, 24)
        XCTAssertEqual(OpenZLCodec.codecName, "openzl")
    }

    func testDecodesGoldenFrame() throws {
        let meta = try Fixtures.meta("frame.openzl")
        let blob = try Fixtures.data("frame.openzl")
        XCTAssertEqual(try OpenZLCodec.frameFormatVersion(blob), 24)
        XCTAssertEqual(try OpenZLCodec.decompress(blob), try Fixtures.data("frame.bin"))
        let records = try OpenZLCodec.decode(blob, sampleCount: meta.sampleCount,
                                             codecFormatVersion: meta.codecFormatVersion,
                                             startTimestamp: meta.startTimestamp, endTimestamp: meta.endTimestamp)
        XCTAssertEqual(records, try Fixtures.records())
    }

    func testDecodesGoldenSingleRecordFrame() throws {
        let meta = try Fixtures.meta("frame_single.openzl")
        let blob = try Fixtures.data("frame_single.openzl")
        let records = try OpenZLCodec.decode(blob, sampleCount: 1, codecFormatVersion: 24,
                                             startTimestamp: meta.startTimestamp, endTimestamp: meta.endTimestamp)
        XCTAssertEqual(AccelRecordPacker.pack(records), try Fixtures.data("frame_single.bin"))
    }

    func testCompressionRoundTrips() throws {
        let records = try Fixtures.records()
        let blob = try OpenZLCodec.compress(AccelRecordPacker.packFrame(records))
        XCTAssertLessThan(blob.count, 10_000)
        XCTAssertEqual(try OpenZLCodec.frameFormatVersion(blob), 24)
        let decoded = try OpenZLCodec.decode(blob, sampleCount: 500, codecFormatVersion: 24,
                                             startTimestamp: records.first!.timestamp,
                                             endTimestamp: records.last!.timestamp)
        XCTAssertEqual(decoded, records)
    }

    func testCompressionMatchesGoldenBytes() throws {
        // Every platform compiles the same lamp_ozl.c, so frames are byte-identical.
        let blob = try OpenZLCodec.compress(try Fixtures.data("frame.bin"))
        XCTAssertEqual(blob, try Fixtures.data("frame.openzl"))
        XCTAssertEqual(FrameMetadata.sha256Hex(blob), try Fixtures.meta("frame.openzl").sha256)
    }

    func testCompressRejectsEmptyAndPartialInput() {
        XCTAssertThrowsError(try OpenZLCodec.compress(Data())) { error in
            guard case SensorStreamError.invalidInput = error else { return XCTFail("\(error)") }
        }
        XCTAssertThrowsError(try OpenZLCodec.compress(Data(count: 21))) { error in
            guard case SensorStreamError.invalidInput = error else { return XCTFail("\(error)") }
        }
    }

    func testDecoderRejectsSampleCountMismatch() throws {
        let meta = try Fixtures.meta("frame.openzl")
        XCTAssertThrowsError(try OpenZLCodec.decode(try Fixtures.data("frame.openzl"), sampleCount: 499,
                                                    codecFormatVersion: 24, startTimestamp: meta.startTimestamp,
                                                    endTimestamp: meta.endTimestamp)) { error in
            XCTAssertEqual(error as? SensorStreamError, .sampleCountMismatch(expected: 499, actual: 500))
        }
    }

    func testDecoderRejectsFormatVersionMismatch() throws {
        let meta = try Fixtures.meta("frame.openzl")
        XCTAssertThrowsError(try OpenZLCodec.decode(try Fixtures.data("frame.openzl"), sampleCount: 500,
                                                    codecFormatVersion: 27, startTimestamp: meta.startTimestamp,
                                                    endTimestamp: meta.endTimestamp)) { error in
            XCTAssertEqual(error as? SensorStreamError, .formatVersionMismatch(expected: 27, actual: 24))
        }
    }

    func testDecoderRejectsTimestampMismatch() throws {
        let meta = try Fixtures.meta("frame.openzl")
        XCTAssertThrowsError(try OpenZLCodec.decode(try Fixtures.data("frame.openzl"), sampleCount: 500,
                                                    codecFormatVersion: 24, startTimestamp: meta.startTimestamp,
                                                    endTimestamp: meta.endTimestamp + 1)) { error in
            guard case SensorStreamError.timestampMismatch = error else { return XCTFail("\(error)") }
        }
    }

    func testDecoderRejectsTruncatedAndGarbageFrames() throws {
        let blob = try Fixtures.data("frame.openzl")
        // Each input fails inside the decoder itself, not on some unrelated error.
        XCTAssertThrowsError(try OpenZLCodec.decode(blob.prefix(blob.count / 2), sampleCount: 500,
                                                    codecFormatVersion: 24, startTimestamp: 0, endTimestamp: 0)) { error in
            guard case SensorStreamError.openZL(let code) = error, code < 0 else { return XCTFail("\(error)") }
        }
        XCTAssertThrowsError(try OpenZLCodec.decompress(Data(repeating: 0xAB, count: 64))) { error in
            guard case SensorStreamError.openZL(let code) = error, code < 0 else { return XCTFail("\(error)") }
        }
        XCTAssertThrowsError(try OpenZLCodec.decompress(Data())) { error in
            guard case SensorStreamError.invalidInput = error else { return XCTFail("\(error)") }
        }
    }

    func testLargestFrameRoundTrips() throws {
        let records = (0..<66_000).map { AccelRecord(timestamp: 1_790_000_100_000 + Int64($0 / 22), x: Float($0 % 97) * 0.01, y: -0.2, z: 9.8) }
        let blob = try OpenZLCodec.compress(AccelRecordPacker.packFrame(records))
        let decoded = try OpenZLCodec.decode(blob, sampleCount: 66_000, codecFormatVersion: 24,
                                             startTimestamp: records.first!.timestamp, endTimestamp: records.last!.timestamp)
        XCTAssertEqual(decoded, records)
    }
}
