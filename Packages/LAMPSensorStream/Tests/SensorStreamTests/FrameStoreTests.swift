import XCTest
@testable import SensorStream

final class FrameStoreTests: XCTestCase {
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

    private func openFileURL(_ frameID: String) -> URL {
        store.openDirectory.appendingPathComponent(spec, isDirectory: true).appendingPathComponent(frameID + ".bin")
    }

    func testDirectoryLayout() {
        XCTAssertEqual(store.openDirectory, root.appendingPathComponent("open"))
        XCTAssertEqual(store.sealedDirectory, root.appendingPathComponent("sealed"))
        XCTAssertEqual(store.quarantineDirectory, root.appendingPathComponent("quarantine"))
        XCTAssertEqual(store.platform, "ios")
    }

    func testDefaultRootIsDocumentsSensorStream() throws {
        let url = try FrameStore.defaultRoot()
        XCTAssertEqual(url.lastPathComponent, "SensorStream")
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, "Documents")
    }

    func testAppendsOpenRecordsAsTheyArrive() throws {
        let records = try Fixtures.records()
        try store.appendOpen(spec: spec, frameID: "f1", records: Array(records[0..<100]))
        XCTAssertEqual(try Data(contentsOf: openFileURL("f1")).count, 2_000)
        try store.appendOpen(spec: spec, frameID: "f1", records: Array(records[100..<250]))
        XCTAssertEqual(AccelRecordPacker.unpack(try Data(contentsOf: openFileURL("f1"))), Array(records[0..<250]))
    }

    func testSealWritesFrameAndSidecarAndDeletesOpenFile() throws {
        let records = try Fixtures.records()
        try store.appendOpen(spec: spec, frameID: "f1", records: records)
        let sealed = try store.seal(spec: spec, frameID: "f1", records: records.reversed())
        XCTAssertFalse(FileManager.default.fileExists(atPath: openFileURL("f1").path))
        XCTAssertEqual(sealed.frameURL.pathExtension, "openzl")
        XCTAssertEqual(sealed.metadataURL.pathExtension, "json")
        XCTAssertEqual(try store.data(for: sealed), try Fixtures.data("frame.openzl"))

        var expected = try Fixtures.meta("frame.openzl")
        expected.platform = "ios"
        XCTAssertEqual(sealed.metadata, expected)
        let sidecar = try JSONDecoder().decode(FrameMetadata.self, from: Data(contentsOf: sealed.metadataURL))
        XCTAssertEqual(sidecar, expected)
        XCTAssertEqual(store.sealedFrames(), [sealed])
    }

    func testSealRejectsEmptyFrame() {
        XCTAssertThrowsError(try store.seal(spec: spec, frameID: "empty", records: []))
    }

    func testRecoversOpenFramesAfterCrash() throws {
        let records = try Fixtures.records()
        try store.appendOpen(spec: spec, frameID: "crashed", records: records)
        // A new process: a fresh store over the same directory.
        let restarted = FrameStore(root: root)
        let recovered = try restarted.recoverOpenFrames()
        XCTAssertEqual(recovered.count, 1)
        XCTAssertEqual(recovered.first?.metadata.sampleCount, 500)
        XCTAssertEqual(try restarted.data(for: recovered[0]), try Fixtures.data("frame.openzl"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: openFileURL("crashed").path))
        XCTAssertEqual(try restarted.recoverOpenFrames(), [])
    }

    func testRecoveryIgnoresTornTrailingRecord() throws {
        let records = try Fixtures.records()
        try store.appendOpen(spec: spec, frameID: "torn", records: records)
        let handle = try FileHandle(forWritingTo: openFileURL("torn"))
        handle.seekToEndOfFile()
        handle.write(Data([1, 2, 3, 4, 5, 6, 7]))
        handle.closeFile()
        let recovered = try store.recoverOpenFrames()
        XCTAssertEqual(recovered.map(\.metadata.sampleCount), [500])
    }

    func testRecoveryDeletesOpenFileWithNoWholeRecord() throws {
        try FileManager.default.createDirectory(at: openFileURL("x").deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data([1, 2, 3]).write(to: openFileURL("tiny"))
        XCTAssertEqual(try store.recoverOpenFrames(), [])
        XCTAssertFalse(FileManager.default.fileExists(atPath: openFileURL("tiny").path))
    }

    func testCrashAfterSidecarBeforeOpenDeleteDoesNotDuplicate() throws {
        let records = try Fixtures.records()
        try store.appendOpen(spec: spec, frameID: "f2", records: records)
        let sealed = try store.seal(spec: spec, frameID: "f2", records: records)
        // Simulate the crash: the open file is still there.
        try store.appendOpen(spec: spec, frameID: "f2", records: records)
        let recovered = try store.recoverOpenFrames()
        XCTAssertEqual(recovered.map(\.id), [sealed.id])
        XCTAssertEqual(store.sealedFrames().count, 1)
        XCTAssertEqual(store.sealedFrames().first?.metadata.sha256, sealed.metadata.sha256)
    }

    func testFrameWithoutSidecarIsNotListed() throws {
        let records = try Fixtures.records()
        let sealed = try store.seal(spec: spec, frameID: "f3", records: records)
        try FileManager.default.removeItem(at: sealed.metadataURL)
        XCTAssertEqual(store.sealedFrames(), [])
    }

    func testSealedFramesAreOldestFirst() throws {
        let records = try Fixtures.records()
        let later = records.map { AccelRecord(timestamp: $0.timestamp + 300_000, x: $0.x, y: $0.y, z: $0.z) }
        let second = try store.seal(spec: spec, frameID: "b", records: later)
        let first = try store.seal(spec: spec, frameID: "a", records: records)
        XCTAssertEqual(store.sealedFrames().map(\.id), [first.id, second.id])
    }

    func testQuarantineAndDelete() throws {
        let records = try Fixtures.records()
        let a = try store.seal(spec: spec, frameID: "a", records: records)
        let b = try store.seal(spec: spec, frameID: "b", records: Array(records.prefix(10)))
        try store.quarantine(a)
        XCTAssertEqual(store.sealedFrames().map(\.id), [b.id])
        XCTAssertEqual(store.quarantinedFrames().map(\.id), [a.id])
        XCTAssertEqual(store.quarantinedFrames().first?.metadata, a.metadata)
        try store.delete(b)
        XCTAssertEqual(store.sealedFrames(), [])
        XCTAssertFalse(FileManager.default.fileExists(atPath: b.frameURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: b.metadataURL.path))
    }

    func testRemoveAllClearsEverything() throws {
        let records = try Fixtures.records()
        try store.appendOpen(spec: spec, frameID: "o", records: records)
        try store.seal(spec: spec, frameID: "s", records: records)
        try store.removeAll()
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.path))
        XCTAssertEqual(store.sealedFrames(), [])
        XCTAssertEqual(try store.recoverOpenFrames(), [])
    }
}
