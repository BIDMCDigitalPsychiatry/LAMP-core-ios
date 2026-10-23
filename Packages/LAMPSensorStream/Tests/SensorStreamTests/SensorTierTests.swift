import XCTest
@testable import SensorStream

final class SensorTierTests: XCTestCase {
    func testSpecsMapToUpdateIntervalsAndRates() throws {
        let expected: [(String, TimeInterval, Int)] = [
            ("lamp.accelerometer10hz", 0.1, 10),
            ("lamp.accelerometer20hz", 0.05, 20),
            ("lamp.accelerometer50hz", 0.02, 50),
            ("lamp.accelerometer100hz", 0.01, 100),
        ]
        for (spec, interval, hz) in expected {
            let tier = try XCTUnwrap(SensorTier(spec: spec), spec)
            XCTAssertEqual(tier.spec, spec)
            XCTAssertEqual(tier.accelerometerUpdateInterval, interval, spec)
            XCTAssertEqual(tier.nominalHz, hz, spec)
            XCTAssertEqual(tier.nominalSamplesPerWindow, hz * 300, spec)
        }
        XCTAssertEqual(SensorTier.all.map(\.spec), expected.map(\.0))
    }

    func testDrainIntervalIsFiveSeconds() {
        XCTAssertEqual(SensorTier.drainInterval, 5.0)
    }

    func testOtherSpecsHaveNoTier() {
        for spec in ["lamp.accelerometer", "lamp.gps", "lamp.gps1m", "lamp.accelerometer200hz", ""] {
            XCTAssertNil(SensorTier(spec: spec), spec)
        }
    }

    func testFastestConfiguredTierWins() {
        XCTAssertEqual(SensorTier.highestConfigured(in: ["lamp.gps", "lamp.accelerometer20hz", "lamp.accelerometer50hz"])?.spec,
                       "lamp.accelerometer50hz")
        XCTAssertEqual(SensorTier.highestConfigured(in: ["lamp.accelerometer100hz", "lamp.accelerometer10hz"])?.spec,
                       "lamp.accelerometer100hz")
        XCTAssertNil(SensorTier.highestConfigured(in: ["lamp.accelerometer", "lamp.gps1m"]))
    }

    func testSensorStreamKeysMatchContract() {
        XCTAssertEqual(SensorStreamKey.allCases.map(\.rawValue),
                       ["lamp.gps1m", "lamp.accelerometer10hz", "lamp.accelerometer20hz",
                        "lamp.accelerometer50hz", "lamp.accelerometer100hz"])
        XCTAssertEqual(SensorStreamKey.accelerometerTiers.count, 4)
        XCTAssertFalse(SensorStreamKey.gps1m.isAccelerometerTier)
        XCTAssertTrue(SensorStreamKey.accelerometer100hz.isAccelerometerTier)
    }
}
