// mindLAMP2Tests

import XCTest
@testable import mindLAMP_2

/// Checks which collectors run when legacy and sensor-stream specs are configured together.
final class SensorStreamRoutingTests: XCTestCase {

    func testNoSensorStreamSpecsKeepsLegacyBehaviour() {
        let routing = SensorStreamRouting(specs: ["lamp.accelerometer", "lamp.gps", "lamp.device_motion"])
        XCTAssertNil(routing.accelerometerSpec)
        XCTAssertTrue(routing.runsLegacyAccelerometer)
        XCTAssertTrue(routing.collectsLegacyGPS)
        XCTAssertFalse(routing.runsGps1m)
        XCTAssertEqual(routing.ignoredAccelerometerSpecs, [])
    }

    func testTierReplacesLegacyAccelerometer() {
        let routing = SensorStreamRouting(specs: ["lamp.accelerometer", "lamp.accelerometer50hz"])
        XCTAssertEqual(routing.accelerometerSpec, "lamp.accelerometer50hz")
        XCTAssertEqual(routing.accelerometerTier?.accelerometerUpdateInterval, 0.02)
        XCTAssertFalse(routing.runsLegacyAccelerometer)
    }

    func testFastestTierWinsAndOthersAreIgnored() {
        let routing = SensorStreamRouting(specs: ["lamp.accelerometer20hz", "lamp.accelerometer100hz",
                                                  "lamp.accelerometer10hz", "lamp.accelerometer"])
        XCTAssertEqual(routing.accelerometerSpec, "lamp.accelerometer100hz")
        XCTAssertEqual(routing.accelerometerTier?.accelerometerUpdateInterval, 0.01)
        XCTAssertEqual(routing.ignoredAccelerometerSpecs, ["lamp.accelerometer10hz", "lamp.accelerometer20hz"])
        XCTAssertFalse(routing.runsLegacyAccelerometer)
    }

    func testEachTierAloneIsRouted() {
        for (spec, interval) in [("lamp.accelerometer10hz", 0.1), ("lamp.accelerometer20hz", 0.05),
                                 ("lamp.accelerometer50hz", 0.02), ("lamp.accelerometer100hz", 0.01)] {
            let routing = SensorStreamRouting(specs: [spec])
            XCTAssertEqual(routing.accelerometerSpec, spec)
            XCTAssertEqual(routing.accelerometerTier?.accelerometerUpdateInterval, interval)
            XCTAssertFalse(routing.runsLegacyAccelerometer)
        }
    }

    func testGps1mRunsAlongsideLegacyGPS() {
        let both = SensorStreamRouting(specs: ["lamp.gps", "lamp.gps1m"])
        XCTAssertTrue(both.runsGps1m)
        XCTAssertTrue(both.collectsLegacyGPS)
        XCTAssertNil(both.accelerometerSpec)

        let only = SensorStreamRouting(specs: ["lamp.gps1m"])
        XCTAssertTrue(only.runsGps1m)
        XCTAssertFalse(only.collectsLegacyGPS)
    }

    func testUnknownSpecsAreIgnored() {
        let routing = SensorStreamRouting(specs: ["lamp.accelerometer200hz", "lamp.gps5m", "custom.sensor"])
        XCTAssertNil(routing.accelerometerSpec)
        XCTAssertFalse(routing.runsGps1m)
        XCTAssertFalse(routing.runsLegacyAccelerometer)
    }
}
