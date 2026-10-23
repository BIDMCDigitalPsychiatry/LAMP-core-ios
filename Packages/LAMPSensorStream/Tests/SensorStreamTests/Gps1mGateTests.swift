import XCTest
@testable import SensorStream

final class Gps1mGateTests: XCTestCase {
    func testAcceptsAtMostOneFixPerMinute() {
        var gate = Gps1mGate()
        XCTAssertEqual(gate.intervalMs, 60_000)
        let t0: Int64 = 1_790_000_160_000
        XCTAssertTrue(gate.accept(timestampMs: t0))
        XCTAssertFalse(gate.accept(timestampMs: t0 + 1_000))
        XCTAssertFalse(gate.accept(timestampMs: t0 + 59_999))
        XCTAssertTrue(gate.accept(timestampMs: t0 + 60_000))
        XCTAssertEqual(gate.lastAcceptedMs, t0 + 60_000)
        XCTAssertFalse(gate.accept(timestampMs: t0 + 90_000))
        XCTAssertTrue(gate.accept(timestampMs: t0 + 125_000))
    }

    func testOneSecondFixesYieldOnePerMinute() {
        var gate = Gps1mGate()
        let accepted = (0..<600).filter { gate.accept(timestampMs: 1_790_000_000_000 + Int64($0) * 1_000) }
        XCTAssertEqual(accepted.count, 10)
    }

    func testBackwardClockJumpIsAccepted() {
        var gate = Gps1mGate()
        XCTAssertTrue(gate.accept(timestampMs: 1_790_000_000_000))
        XCTAssertFalse(gate.accept(timestampMs: 1_789_999_990_000))
        XCTAssertTrue(gate.accept(timestampMs: 1_789_996_400_000))
    }

    func testResetAcceptsNextFix() {
        var gate = Gps1mGate()
        XCTAssertTrue(gate.accept(timestampMs: 1_000_000))
        gate.reset()
        XCTAssertNil(gate.lastAcceptedMs)
        XCTAssertTrue(gate.accept(timestampMs: 1_000_001))
    }
}
