import XCTest
@testable import SensorStream

final class AccelRecordPackerTests: XCTestCase {
    func testRecordSizeIsTwentyBytes() {
        XCTAssertEqual(AccelRecordPacker.recordSize, 20)
    }

    func testPackingIsByteIdenticalToGoldenFrame() throws {
        let records = try Fixtures.records()
        XCTAssertEqual(records.count, 500)
        let packed = AccelRecordPacker.packFrame(records)
        XCTAssertEqual(packed.count, 10_000)
        XCTAssertEqual(packed, try Fixtures.data("frame.bin"))
    }

    func testSingleRecordFrameIsByteIdentical() throws {
        let golden = try Fixtures.data("frame_single.bin")
        let unpacked = AccelRecordPacker.unpack(golden)
        XCTAssertEqual(unpacked.count, 1)
        XCTAssertEqual(AccelRecordPacker.pack(unpacked), golden)
    }

    func testLayoutIsLittleEndianTimestampThenThreeFloats() {
        let record = AccelRecord(timestamp: 0x0102_0304_0506_0708, x: 1.0, y: -2.0, z: 9.80665)
        let packed = AccelRecordPacker.pack([record])
        guard packed.count == 20 else { return XCTFail("packed \(packed.count) bytes, want 20") }
        XCTAssertEqual(Array(packed[0..<8]), [0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01])
        XCTAssertEqual(Array(packed[8..<12]), [0x00, 0x00, 0x80, 0x3F])
        XCTAssertEqual(Array(packed[12..<16]), [0x00, 0x00, 0x00, 0xC0])
        XCTAssertEqual(Array(packed[16..<20]), withUnsafeBytes(of: Float(9.80665).bitPattern.littleEndian, Array.init))
    }

    func testDuplicateMillisecondsAreKeptAndStablySorted() throws {
        let edge = try Fixtures.edgeCase("duplicate_ms")
        let input = try Fixtures.rows(edge["input"])
        let expected = try Fixtures.rows(edge["expected_sorted"])
        XCTAssertEqual(AccelRecordPacker.stableSorted(input), expected)
        XCTAssertEqual(Fixtures.hex(AccelRecordPacker.packFrame(input)), edge["expected_packed_hex"] as? String)
    }

    func testStableSortKeepsArrivalOrderForManyEqualTimestamps() {
        let input = (0..<1_000).map { AccelRecord(timestamp: Int64(($0 * 7) % 5), x: Float($0), y: 0, z: 0) }
        let sorted = AccelRecordPacker.stableSorted(input)
        XCTAssertEqual(sorted.count, input.count)
        for (a, b) in zip(sorted, sorted.dropFirst()) {
            XCTAssertLessThanOrEqual(a.timestamp, b.timestamp)
            if a.timestamp == b.timestamp { XCTAssertLessThan(a.x, b.x) }
        }
    }

    func testUnpackRoundTripsAndIgnoresTrailingPartialRecord() throws {
        let records = try Fixtures.records()
        var packed = AccelRecordPacker.pack(records)
        XCTAssertEqual(AccelRecordPacker.unpack(packed), records)
        packed.append(contentsOf: [1, 2, 3])
        XCTAssertEqual(AccelRecordPacker.unpack(packed), records)
    }
}
