import Foundation

/// A compressed frame on disk with its sidecar metadata.
public struct SealedFrame: Equatable {
    public let id: String
    public let frameURL: URL
    public let metadataURL: URL
    public let metadata: FrameMetadata
}

/// Stores frames under `Documents/SensorStream/{open,sealed,quarantine}`.
///
/// - `open/<spec>/<frame id>.bin`: raw 20-byte records, appended as they arrive.
/// - `sealed/<frame id>.openzl` and `sealed/<frame id>.json`: the compressed
///   frame and its upload metadata.
/// - `quarantine/`: frames the server rejected for good, kept for inspection.
///
/// Sealing writes the compressed file, then the sidecar JSON (the commit
/// marker), then deletes the open file. `recoverOpenFrames()` reseals an open
/// file only when its frame has no sidecar yet. If the sidecar exists, the
/// sealed frame is complete (it can hold records that never reached the open
/// file), so recovery deletes the stale open file instead of overwriting it.
public final class FrameStore {
    /// The directory name under `Documents`.
    public static let directoryName = "SensorStream"
    /// The extension of compressed frame files.
    public static let frameExtension = "openzl"

    /// Returns `Documents/SensorStream` in the app's sandbox.
    public static func defaultRoot() throws -> URL {
        try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(directoryName, isDirectory: true)
    }

    public let root: URL
    public let platform: String
    public var openDirectory: URL { root.appendingPathComponent("open", isDirectory: true) }
    public var sealedDirectory: URL { root.appendingPathComponent("sealed", isDirectory: true) }
    public var quarantineDirectory: URL { root.appendingPathComponent("quarantine", isDirectory: true) }

    private let fileManager = FileManager.default
    private let lock = NSLock()

    public init(root: URL, platform: String = "ios") {
        self.root = root
        self.platform = platform
    }

    /// Appends records to the open file of frame `frameID`.
    public func appendOpen(spec: String, frameID: String, records: [AccelRecord]) throws {
        guard !records.isEmpty else { return }
        lock.lock(); defer { lock.unlock() }
        let url = openURL(spec: spec, frameID: frameID)
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let bytes = AccelRecordPacker.pack(records)
        if fileManager.fileExists(atPath: url.path) {
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            let end = try handle.seekToEnd()
            // Drop a torn trailing record from an earlier crash so records stay aligned.
            let aligned = end - end % UInt64(AccelRecordPacker.recordSize)
            if aligned != end {
                try handle.truncate(atOffset: aligned)
                try handle.seek(toOffset: aligned)
            }
            try handle.write(contentsOf: bytes)
        } else {
            try bytes.write(to: url)
        }
    }

    /// Compresses `records` as frame `frameID`, writes it to `sealed/`, and
    /// deletes the frame's open file.
    @discardableResult
    public func seal(spec: String, frameID: String, records: [AccelRecord]) throws -> SealedFrame {
        guard !records.isEmpty else { throw SensorStreamError.invalidInput("a frame holds at least one record") }
        lock.lock(); defer { lock.unlock() }
        return try sealLocked(spec: spec, frameID: frameID, records: records)
    }

    /// Seals every open file left by a previous run (for example, after a crash).
    @discardableResult
    public func recoverOpenFrames() throws -> [SealedFrame] {
        lock.lock(); defer { lock.unlock() }
        var recovered: [SealedFrame] = []
        for specDirectory in contents(of: openDirectory) {
            let spec = specDirectory.lastPathComponent
            for file in contents(of: specDirectory) where file.pathExtension == "bin" {
                let frameID = file.deletingPathExtension().lastPathComponent
                if let committed = loadFrame(id: frameID, in: sealedDirectory) {
                    // The process died between the sidecar write and the open-file delete.
                    try fileManager.removeItem(at: file)
                    recovered.append(committed)
                    continue
                }
                let records = AccelRecordPacker.unpack(try Data(contentsOf: file))
                if records.isEmpty {
                    try fileManager.removeItem(at: file)
                } else {
                    recovered.append(try sealLocked(spec: spec, frameID: frameID, records: records))
                }
            }
        }
        return recovered.sorted(by: Self.oldestFirst)
    }

    /// Returns the sealed frames, oldest `start_timestamp` first.
    public func sealedFrames() -> [SealedFrame] {
        lock.lock(); defer { lock.unlock() }
        return listFrames(in: sealedDirectory)
    }

    /// Returns the quarantined frames.
    public func quarantinedFrames() -> [SealedFrame] {
        lock.lock(); defer { lock.unlock() }
        return listFrames(in: quarantineDirectory)
    }

    /// Reads a frame's compressed bytes.
    public func data(for frame: SealedFrame) throws -> Data {
        try Data(contentsOf: frame.frameURL)
    }

    /// Deletes an uploaded frame.
    public func delete(_ frame: SealedFrame) throws {
        lock.lock(); defer { lock.unlock() }
        // Remove the commit marker first, so a crash leaves an unlisted orphan, not a resend.
        try removeIfPresent(frame.metadataURL)
        try removeIfPresent(frame.frameURL)
    }

    /// Moves a rejected frame to `quarantine/`.
    public func quarantine(_ frame: SealedFrame) throws {
        lock.lock(); defer { lock.unlock() }
        try fileManager.createDirectory(at: quarantineDirectory, withIntermediateDirectories: true)
        let frameDestination = quarantineDirectory.appendingPathComponent(frame.frameURL.lastPathComponent)
        let metadataDestination = quarantineDirectory.appendingPathComponent(frame.metadataURL.lastPathComponent)
        try removeIfPresent(frameDestination)
        try removeIfPresent(metadataDestination)
        try fileManager.moveItem(at: frame.frameURL, to: frameDestination)
        try fileManager.moveItem(at: frame.metadataURL, to: metadataDestination)
    }

    /// Deletes everything under the root (used on logout).
    public func removeAll() throws {
        lock.lock(); defer { lock.unlock() }
        try removeIfPresent(root)
    }

    // MARK: - Private

    private func openURL(spec: String, frameID: String) -> URL {
        openDirectory.appendingPathComponent(spec, isDirectory: true).appendingPathComponent(frameID + ".bin")
    }

    private func sealLocked(spec: String, frameID: String, records: [AccelRecord]) throws -> SealedFrame {
        let sorted = AccelRecordPacker.stableSorted(records)
        let compressed = try OpenZLCodec.compress(AccelRecordPacker.pack(sorted))
        let metadata = FrameMetadata.make(sensorSpec: spec, records: sorted, compressed: compressed, platform: platform)
        try fileManager.createDirectory(at: sealedDirectory, withIntermediateDirectories: true)
        let frameURL = sealedDirectory.appendingPathComponent(frameID).appendingPathExtension(Self.frameExtension)
        let metadataURL = sealedDirectory.appendingPathComponent(frameID).appendingPathExtension("json")
        try compressed.write(to: frameURL, options: .atomic)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(metadata).write(to: metadataURL, options: .atomic)
        try removeIfPresent(openURL(spec: spec, frameID: frameID))
        return SealedFrame(id: frameID, frameURL: frameURL, metadataURL: metadataURL, metadata: metadata)
    }

    private func listFrames(in directory: URL) -> [SealedFrame] {
        contents(of: directory)
            .filter { $0.pathExtension == "json" }
            // Rebuild the URLs from `directory`; listings can resolve symlinks (/var -> /private/var).
            .compactMap { loadFrame(id: $0.deletingPathExtension().lastPathComponent, in: directory) }
            .sorted(by: Self.oldestFirst)
    }

    /// Returns frame `frameID` in `directory` if both its sidecar and its compressed file exist.
    private func loadFrame(id frameID: String, in directory: URL) -> SealedFrame? {
        let metadataURL = directory.appendingPathComponent(frameID).appendingPathExtension("json")
        let frameURL = directory.appendingPathComponent(frameID).appendingPathExtension(Self.frameExtension)
        guard fileManager.fileExists(atPath: frameURL.path),
              let data = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode(FrameMetadata.self, from: data) else { return nil }
        return SealedFrame(id: frameID, frameURL: frameURL, metadataURL: metadataURL, metadata: metadata)
    }

    private func contents(of directory: URL) -> [URL] {
        (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
    }

    private func removeIfPresent(_ url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    private static func oldestFirst(_ a: SealedFrame, _ b: SealedFrame) -> Bool {
        (a.metadata.startTimestamp, a.id) < (b.metadata.startTimestamp, b.id)
    }
}
