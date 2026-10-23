import XCTest
@testable import SensorStream

final class FramePartitionerTests: XCTestCase {
    private func record(_ ts: Int64, _ x: Float = 0) -> AccelRecord {
        AccelRecord(timestamp: ts, x: x, y: 0, z: 9.80665)
    }

    func testWindowIndexAndDeadline() {
        XCTAssertEqual(FramePartitioner.window(of: 1_790_000_399_999), 5_966_667)
        XCTAssertEqual(FramePartitioner.window(of: 1_790_000_400_000), 5_966_668)
        XCTAssertEqual(FramePartitioner.window(of: 0), 0)
        XCTAssertEqual(FramePartitioner.window(of: -1), -1)
        XCTAssertEqual(FramePartitioner.closeDeadline(forWindow: 5_966_667), 1_790_000_400_000 + 15_000)
    }

    func testWindowSplitGoldenVector() throws {
        let edge = try Fixtures.edgeCase("window_split")
        XCTAssertEqual((edge["window_ms"] as? NSNumber)?.int64Value, FramePartitioner.windowMs)
        let arrivals = try XCTUnwrap(edge["arrivals"] as? [Any])
        let partitioner = FramePartitioner()
        var frames: [PartitionedFrame] = []
        for batch in arrivals {
            frames += partitioner.append(try Fixtures.rows(batch))
        }
        if let last = partitioner.closeOpenFrame() { frames.append(last) }

        let expected = try XCTUnwrap(edge["expected_frames"] as? [[String: Any]])
        XCTAssertEqual(frames.count, expected.count)
        for (frame, want) in zip(frames, expected) {
            XCTAssertEqual(frame.window, (want["window"] as? NSNumber)?.int64Value)
            XCTAssertEqual(frame.startTimestamp, (want["start_timestamp"] as? NSNumber)?.int64Value)
            XCTAssertEqual(frame.endTimestamp, (want["end_timestamp"] as? NSNumber)?.int64Value)
            XCTAssertEqual(frame.records.map(\.timestamp), (want["timestamps"] as? [NSNumber])?.map(\.int64Value))
            XCTAssertEqual(frame.late, (want["late"] as? Bool) ?? false)
        }
        XCTAssertEqual(Set(frames.map(\.id)).count, frames.count, "every frame has its own id")
    }

    func testRecordFromLaterWindowClosesOpenFrame() {
        let partitioner = FramePartitioner()
        XCTAssertEqual(partitioner.append([record(1_790_000_100_000), record(1_790_000_100_020)]), [])
        XCTAssertEqual(partitioner.openFrame?.window, 5_966_667)
        let closed = partitioner.append([record(1_790_000_400_000)])
        XCTAssertEqual(closed.count, 1)
        XCTAssertEqual(closed.first?.records.count, 2)
        XCTAssertEqual(partitioner.openFrame?.window, 5_966_668)
    }

    func testWallClockDeadlineClosesOpenFrame() {
        let partitioner = FramePartitioner()
        _ = partitioner.append([record(1_790_000_399_000)])
        let deadline = FramePartitioner.closeDeadline(forWindow: 5_966_667)
        XCTAssertEqual(partitioner.closeExpired(nowMs: deadline - 1), [])
        let closed = partitioner.closeExpired(nowMs: deadline)
        XCTAssertEqual(closed.map(\.startTimestamp), [1_790_000_399_000])
        XCTAssertNil(partitioner.openFrame)
        // A record for the closed window is late: a new partial frame, never dropped.
        let late = partitioner.append([record(1_790_000_399_500)])
        XCTAssertEqual(late.count, 1)
        XCTAssertEqual(late.first?.late, true)
        XCTAssertEqual(late.first?.window, 5_966_667)
        XCTAssertNil(partitioner.openFrame)
    }

    func testCollectorStopClosesFrameAndRestartOpensNewFrameForSameWindow() {
        let partitioner = FramePartitioner()
        _ = partitioner.append([record(1_790_000_100_000)])
        let stopped = partitioner.closeOpenFrame()
        XCTAssertEqual(stopped?.records.count, 1)
        XCTAssertEqual(stopped?.late, false)
        XCTAssertNil(partitioner.closeOpenFrame())
        XCTAssertEqual(partitioner.append([record(1_790_000_200_000)]), [])
        XCTAssertEqual(partitioner.openFrame?.window, 5_966_667)
        XCTAssertNotEqual(partitioner.openFrame?.id, stopped?.id)
    }

    func testDuplicateMillisecondsStayInFrameStablySorted() throws {
        let edge = try Fixtures.edgeCase("duplicate_ms")
        let partitioner = FramePartitioner()
        _ = partitioner.append(try Fixtures.rows(edge["input"]))
        let frame = try XCTUnwrap(partitioner.closeOpenFrame())
        XCTAssertEqual(frame.records, try Fixtures.rows(edge["expected_sorted"]))
    }

    func testLateRecordsForSeveralWindowsInOneBatch() {
        let partitioner = FramePartitioner()
        _ = partitioner.append([record(1_790_000_100_000), record(1_790_000_400_000), record(1_790_000_700_000)])
        // Open window is now 5_966_669; two earlier windows are closed.
        let late = partitioner.append([record(1_790_000_100_010), record(1_790_000_400_010), record(1_790_000_100_005), record(1_790_000_700_010)])
        XCTAssertEqual(late.map(\.window), [5_966_667, 5_966_668])
        XCTAssertEqual(late.first?.records.map(\.timestamp), [1_790_000_100_005, 1_790_000_100_010])
        XCTAssertTrue(late.allSatisfy(\.late))
        XCTAssertEqual(partitioner.openFrame?.records.count, 2)
    }

    func testFullFrameClosesAndContinuesInSameWindow() {
        let partitioner = FramePartitioner()
        let batch = (0..<(FramePartitioner.maxRecordsPerFrame + 10)).map { record(1_790_000_100_000 + Int64($0 / 50)) }
        let closed = partitioner.append(batch)
        XCTAssertEqual(closed.count, 1)
        XCTAssertEqual(closed.first?.records.count, FramePartitioner.maxRecordsPerFrame)
        XCTAssertEqual(closed.first?.late, false)
        XCTAssertEqual(partitioner.openFrame?.records.count, 10)
    }

    func testNeverDropsRecords() {
        let partitioner = FramePartitioner()
        var generator = SystemRandomNumberGenerator()
        var delivered = 0
        var collected = 0
        for _ in 0..<50 {
            let base: Int64 = 1_790_000_000_000 + Int64.random(in: 0..<3_000_000, using: &generator)
            let batch = (0..<Int.random(in: 1...200, using: &generator)).map { _ in
                record(base + Int64.random(in: -400_000...400_000, using: &generator))
            }
            delivered += batch.count
            collected += partitioner.append(batch).reduce(0) { $0 + $1.records.count }
            collected += partitioner.closeExpired(nowMs: base).reduce(0) { $0 + $1.records.count }
        }
        collected += partitioner.closeOpenFrame()?.records.count ?? 0
        XCTAssertEqual(collected, delivered)
    }

    func testFramesNeverSpanWindows() {
        let partitioner = FramePartitioner()
        var frames: [PartitionedFrame] = []
        var delivered: [AccelRecord] = []
        for i in 0..<100 {
            let batch = (0..<60).map { record(1_790_000_000_000 + Int64(i * 60 + $0) * 211) }
            delivered += batch
            frames += partitioner.append(batch.shuffled())
        }
        if let last = partitioner.closeOpenFrame() { frames.append(last) }
        // Every record comes back, and every window it touched has a frame.
        XCTAssertEqual(frames.reduce(0) { $0 + $1.records.count }, 6_000)
        XCTAssertEqual(Set(frames.map(\.window)), Set(delivered.map { FramePartitioner.window(of: $0.timestamp) }))
        XCTAssertGreaterThan(frames.count, 1)
        for frame in frames {
            XCTAssertFalse(frame.records.isEmpty)
            XCTAssertEqual(FramePartitioner.window(of: frame.startTimestamp), frame.window)
            XCTAssertEqual(FramePartitioner.window(of: frame.endTimestamp), frame.window)
            XCTAssertEqual(frame.records, AccelRecordPacker.stableSorted(frame.records))
        }
    }
}
