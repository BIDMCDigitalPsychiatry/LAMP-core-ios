import XCTest
@testable import SensorStream

/// Drives the collector's drain logic with simulated CoreMotion samples and clocks.
final class AccelerometerSessionTests: XCTestCase {
    private let spec = "lamp.accelerometer50hz"
    private var root: URL!
    private var store: FrameStore!

    override func setUpWithError() throws {
        root = try Fixtures.temporaryDirectory().appendingPathComponent(FrameStore.directoryName, isDirectory: true)
        store = FrameStore(root: root)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root.deletingLastPathComponent())
    }

    /// Samples taken every `step` seconds of uptime in `(after, through]`, each received at
    /// once; `wall` maps an uptime to the wall clock at that moment.
    private func samples(after: Double, through: Double, step: Double,
                         wall: (Double) -> Double) -> [MotionSample] {
        stride(from: after + step, through: through + step / 2, by: step).map { uptime in
            MotionSample(uptime: uptime, xG: 0, yG: 0, zG: -1,
                         receivedWallEpochSeconds: wall(uptime), receivedUptimeSeconds: uptime)
        }
    }

    private func timestamps(_ frames: [SealedFrame]) throws -> [Int64] {
        try frames.flatMap { frame -> [Int64] in
            let meta = frame.metadata
            return try OpenZLCodec.decode(try store.data(for: frame), sampleCount: meta.sampleCount,
                                          codecFormatVersion: meta.codecFormatVersion,
                                          startTimestamp: meta.startTimestamp, endTimestamp: meta.endTimestamp)
                .map(\.timestamp)
        }
    }

    private func epochMs(_ wallSeconds: Double) -> Int64 { Int64(wallSeconds * 1_000) }

    /// Compares timestamps to within 1 ms: a session offset taken from a wall clock near
    /// 1.79e9 s carries `Double` rounding of a few hundred nanoseconds, which can move a
    /// floor across a millisecond boundary. The defects these tests catch are 600,000 ms.
    private func assertTimestamps(_ actual: [Int64], _ expected: [Int64],
                                  file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actual.count, expected.count, file: file, line: line)
        let worst = zip(actual, expected).map { abs($0 - $1) }.max() ?? 0
        XCTAssertLessThanOrEqual(worst, 1, "\(actual) vs \(expected)", file: file, line: line)
    }

    func testDrainWithoutDriftUsesTheSessionOffset() throws {
        let session = AccelerometerSession(recorder: FrameRecorder(spec: spec, store: store))
        try session.start(wallEpochSeconds: 1_790_000_100, uptimeSeconds: 1_000)
        let batch = samples(after: 1_000, through: 1_005, step: 0.125) { 1_790_000_100 + ($0 - 1_000) }
        var sealed = try session.drain(batch, wallEpochSeconds: 1_790_000_105, uptimeSeconds: 1_005)
        XCTAssertEqual(sealed, [])
        sealed += try session.stop([], wallEpochSeconds: 1_790_000_105, uptimeSeconds: 1_005)
        XCTAssertEqual(try timestamps(sealed), batch.map { epochMs(1_790_000_100 + ($0.uptime - 1_000)) })
        XCTAssertEqual(sealed.first?.metadata.sampleCount, 40)
    }

    /// The device sleeps 600 s in the middle of a drain interval: uptime stops, the wall clock runs.
    func testSamplesBufferedBeforeDeepSleepKeepTheirSessionOffset() throws {
        let session = AccelerometerSession(recorder: FrameRecorder(spec: spec, store: store))
        try session.start(wallEpochSeconds: 1_790_000_000, uptimeSeconds: 1_000)
        let beforeSleep = samples(after: 1_000, through: 1_004, step: 0.125) { 1_790_000_000 + ($0 - 1_000) }
        let afterWake = samples(after: 1_004, through: 1_005, step: 0.125) { 1_790_000_600 + ($0 - 1_000) }

        var sealed = try session.drain(beforeSleep + afterWake, wallEpochSeconds: 1_790_000_605, uptimeSeconds: 1_005)
        sealed += try session.stop([], wallEpochSeconds: 1_790_000_605, uptimeSeconds: 1_005)

        let expected = beforeSleep.map { epochMs(1_790_000_000 + ($0.uptime - 1_000)) }
            + afterWake.map { epochMs(1_790_000_600 + ($0.uptime - 1_000)) }
        assertTimestamps(try timestamps(sealed), expected)
        // The session restart closes the pre-sleep frame at its last pre-sleep sample.
        assertTimestamps(sealed.map(\.metadata.endTimestamp), [1_790_000_004_000, 1_790_000_605_000])
    }

    /// The device sleeps after the last buffered sample; the drain itself sees the drift.
    func testDriftAfterTheLastSampleKeepsTheOldOffsetForTheBatch() throws {
        let session = AccelerometerSession(recorder: FrameRecorder(spec: spec, store: store))
        try session.start(wallEpochSeconds: 1_790_000_000, uptimeSeconds: 1_000)
        let beforeSleep = samples(after: 1_000, through: 1_004, step: 0.125) { 1_790_000_000 + ($0 - 1_000) }
        var sealed = try session.drain(beforeSleep, wallEpochSeconds: 1_790_000_604.5, uptimeSeconds: 1_004.5)
        let afterWake = samples(after: 1_004.5, through: 1_005, step: 0.125) { 1_790_000_600 + ($0 - 1_000) }
        sealed += try session.stop(afterWake, wallEpochSeconds: 1_790_000_605, uptimeSeconds: 1_005)

        let expected = beforeSleep.map { epochMs(1_790_000_000 + ($0.uptime - 1_000)) }
            + afterWake.map { epochMs(1_790_000_600 + ($0.uptime - 1_000)) }
        assertTimestamps(try timestamps(sealed), expected)
        XCTAssertEqual(sealed.count, 2)
    }

    /// After the wall clock moves back 15 minutes, frames still follow windows, not drains.
    func testBackwardClockJumpKeepsOneFramePerWindow() throws {
        let session = AccelerometerSession(recorder: FrameRecorder(spec: spec, store: store))
        let start = 1_790_000_100.0  // A window boundary.
        try session.start(wallEpochSeconds: start, uptimeSeconds: 1_000)
        var delivered = 0
        var beforeJump: [SealedFrame] = []
        for drain in 0..<180 {  // 15 minutes of 5 s drains at 50 Hz.
            let uptime = 1_000 + Double(drain + 1) * 5
            let batch = samples(after: uptime - 5, through: uptime, step: 0.02) { start + ($0 - 1_000) }
            delivered += batch.count
            beforeJump += try session.drain(batch, wallEpochSeconds: start + (uptime - 1_000), uptimeSeconds: uptime)
        }
        var afterJump: [SealedFrame] = []
        for drain in 180..<240 {  // The wall clock is now 900 s behind; 5 more minutes.
            let uptime = 1_000 + Double(drain + 1) * 5
            let batch = samples(after: uptime - 5, through: uptime, step: 0.02) { start + ($0 - 1_000) - 900 }
            delivered += batch.count
            afterJump += try session.drain(batch, wallEpochSeconds: start + (uptime - 1_000) - 900, uptimeSeconds: uptime)
        }
        afterJump += try session.stop([], wallEpochSeconds: start + 300, uptimeSeconds: 2_200)

        XCTAssertEqual((beforeJump + afterJump).reduce(0) { $0 + $1.metadata.sampleCount }, delivered)
        // The restart closes the pre-jump frame, then 5 minutes span about one window.
        XCTAssertLessThanOrEqual(afterJump.count, 3, "one frame per window, not one per drain")
    }
}
