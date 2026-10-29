import XCTest
@testable import SensorStream

final class UnitConversionTests: XCTestCase {
    func testUnitsAtRestMatchGoldenCases() throws {
        let edge = try Fixtures.edgeCase("units_at_rest")
        XCTAssertEqual(edge["gravity"] as? Double, UnitConversion.standardGravity)
        let cases = try XCTUnwrap(edge["cases"] as? [[String: [Double]]])
        XCTAssertEqual(cases.count, 3)
        for testCase in cases {
            let g = try XCTUnwrap(testCase["ios_g"])
            let expected = try XCTUnwrap(testCase["expected_ms2"])
            let record = UnitConversion.record(timestamp: 7, xG: g[0], yG: g[1], zG: g[2])
            // Numeric compare: -0.0 equals 0.0.
            XCTAssertEqual(record.x, Float(expected[0]))
            XCTAssertEqual(record.y, Float(expected[1]))
            XCTAssertEqual(record.z, Float(expected[2]))
            XCTAssertEqual(record.timestamp, 7)
        }
    }

    func testFaceUpReadsPositiveGravityOnZ() throws {
        let edge = try Fixtures.edgeCase("units_at_rest")
        let android = try XCTUnwrap(edge["android_at_rest_face_up_ms2"] as? [Double])
        XCTAssertEqual(UnitConversion.metersPerSecondSquared(fromG: -1.0), Float(android[2]))
        XCTAssertGreaterThan(UnitConversion.metersPerSecondSquared(fromG: -1.0), 9.8)
    }
}
