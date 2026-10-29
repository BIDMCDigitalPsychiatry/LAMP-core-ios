import XCTest
@testable import SensorStream

final class SensorClockTests: XCTestCase {
    func testNoTimestampsBeforeSessionStarts() {
        let clock = SensorClock()
        XCTAssertNil(clock.epochMs(uptimeSeconds: 10))
        XCTAssertNil(clock.offsetNs)
    }

    func testConvertsUptimeToEpochMillisecondsWithSessionOffset() {
        var clock = SensorClock()
        clock.startSession(wallEpochSeconds: 1_790_000_000.0, uptimeSeconds: 1_000.0)
        XCTAssertEqual(clock.session, 1)
        XCTAssertEqual(clock.offsetNs, 1_789_999_000 * 1_000_000_000)
        XCTAssertEqual(clock.epochMs(uptimeSeconds: 1_000.0), 1_790_000_000_000)
        XCTAssertEqual(clock.epochMs(uptimeSeconds: 1_000.0205), 1_790_000_000_020)
        XCTAssertEqual(clock.epochMs(uptimeSeconds: 1_100.5), 1_790_000_100_500)
    }

    func testFloorsToMilliseconds() {
        var clock = SensorClock()
        clock.startSession(wallEpochSeconds: 1_790_000_000.0, uptimeSeconds: 1_000.0)
        XCTAssertEqual(clock.epochMs(uptimeSeconds: 1_000.020_999), 1_790_000_000_020)
        XCTAssertEqual(clock.epochMs(uptimeSeconds: 999.999_5), 1_789_999_999_999)
    }

    func testOffsetIsFixedForTheSession() {
        var clock = SensorClock()
        clock.startSession(wallEpochSeconds: 1_790_000_000.0, uptimeSeconds: 1_000.0)
        // The wall clock moves 500 ms relative to uptime: within tolerance, so no restart.
        XCTAssertEqual(clock.driftMs(wallEpochSeconds: 1_790_000_060.5, uptimeSeconds: 1_060.0), 500)
        XCTAssertFalse(clock.restartIfDrifted(wallEpochSeconds: 1_790_000_060.5, uptimeSeconds: 1_060.0))
        XCTAssertEqual(clock.session, 1)
        XCTAssertEqual(clock.epochMs(uptimeSeconds: 1_060.0), 1_790_000_060_000)
    }

    func testDriftOverOneSecondStartsNewSession() {
        var clock = SensorClock()
        clock.startSession(wallEpochSeconds: 1_790_000_000.0, uptimeSeconds: 1_000.0)
        let before = clock.epochMs(uptimeSeconds: 1_010.0)
        // An NTP correction moves the wall clock back 2 s.
        XCTAssertEqual(clock.driftMs(wallEpochSeconds: 1_790_000_008.0, uptimeSeconds: 1_010.0), -2_000)
        XCTAssertTrue(clock.restartIfDrifted(wallEpochSeconds: 1_790_000_008.0, uptimeSeconds: 1_010.0))
        XCTAssertEqual(clock.session, 2)
        XCTAssertEqual(clock.epochMs(uptimeSeconds: 1_010.0), 1_790_000_008_000)
        XCTAssertEqual(before, 1_790_000_010_000)
    }

    func testDriftOfExactlyOneSecondIsTolerated() {
        var clock = SensorClock()
        clock.startSession(wallEpochSeconds: 1_790_000_000.0, uptimeSeconds: 1_000.0)
        XCTAssertFalse(clock.restartIfDrifted(wallEpochSeconds: 1_790_000_011.0, uptimeSeconds: 1_010.0))
        XCTAssertTrue(clock.restartIfDrifted(wallEpochSeconds: 1_790_000_011.002, uptimeSeconds: 1_010.0))
    }
}
