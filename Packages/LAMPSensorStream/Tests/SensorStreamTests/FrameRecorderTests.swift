import XCTest
@testable import SensorStream

final class FrameRecorderTests: XCTestCase {
    private let spec = "lamp.accelerometer50hz"
    private var root: URL!

    override func setUpWithError() throws {
        root = try Fixtures.temporaryDirectory().appendingPathComponent(FrameStore.directoryName, isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root.deletingLastPathComponent())
    }

    private func decode(_ frame: SealedFrame, _ store: FrameStore) throws -> [AccelRecord] {
        let meta = frame.metadata
        return try OpenZLCodec.decode(try store.data(for: frame), sampleCount: meta.sampleCount,
                                      codecFormatVersion: meta.codecFormatVersion,
                                      startTimestamp: meta.startTimestamp, endTimestamp: meta.endTimestamp)
    }

    func testWindowSplitArrivalsBecomeThreeSealedFrames() throws {
        let edge = try Fixtures.edgeCase("window_split")
        let arrivals = try XCTUnwrap(edge["arrivals"] as? [Any])
        let store = FrameStore(root: root)
        let recorder = FrameRecorder(spec: spec, store: store)
        var sealed: [SealedFrame] = []
        for batch in arrivals {
            sealed += try recorder.ingest(try Fixtures.rows(batch), nowMs: 1_790_000_400_100)
        }
        sealed += try recorder.closeOpenFrame()
        let expected = try XCTUnwrap(edge["expected_frames"] as? [[String: Any]])
        XCTAssertEqual(try sealed.map { try decode($0, store).map(\.timestamp) },
                       expected.map { ($0["timestamps"] as? [NSNumber])?.map(\.int64Value) ?? [] })
        XCTAssertEqual(store.sealedFrames().count, 3)
        XCTAssertTrue(sealed.allSatisfy { $0.metadata.sensorSpec == spec && $0.metadata.platform == "ios" })
    }

    func testOpenFrameIsOnDiskAfterEveryDrain() throws {
        let records = try Fixtures.records()
        let store = FrameStore(root: root)
        let recorder = FrameRecorder(spec: spec, store: store)
        for chunk in stride(from: 0, to: 500, by: 250) {
            XCTAssertEqual(try recorder.ingest(Array(records[chunk..<chunk + 250]), nowMs: records[0].timestamp), [])
        }
        // The process dies here: nothing was sealed, but every record is on disk.
        let recovered = try FrameStore(root: root).recoverOpenFrames()
        XCTAssertEqual(recovered.count, 1)
        XCTAssertEqual(try decode(recovered[0], store), records)
    }

    func testWallClockDeadlineSealsOpenFrame() throws {
        let records = try Fixtures.records()
        let store = FrameStore(root: root)
        let recorder = FrameRecorder(spec: spec, store: store)
        XCTAssertEqual(try recorder.ingest(records, nowMs: records[0].timestamp), [])
        let deadline = FramePartitioner.closeDeadline(forWindow: FramePartitioner.window(of: records[0].timestamp))
        let sealed = try recorder.ingest([], nowMs: deadline)
        XCTAssertEqual(sealed.count, 1)
        XCTAssertEqual(try store.data(for: sealed[0]), try Fixtures.data("frame.openzl"))
        XCTAssertEqual(try FrameStore(root: root).recoverOpenFrames(), [], "no open file is left behind")
    }
}
