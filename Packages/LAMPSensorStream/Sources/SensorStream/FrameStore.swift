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
/// Open frames are raw records appended as they arrive. Sealing compresses a
/// frame, writes the compressed file, then the sidecar JSON (the commit
/// marker), then deletes the open file, so a crash at any step loses nothing.
public final class FrameStore {
    /// The directory name under `Documents`.
    public static let directoryName = "SensorStream"
    /// The extension of compressed frame files.
    public static let frameExtension = "openzl"

    /// Returns `Documents/SensorStream` in the app's sandbox.
    public static func defaultRoot() throws -> URL {
        throw SensorStreamError.notImplemented
    }

    public let root: URL
    public let platform: String
    public var openDirectory: URL { root.appendingPathComponent("open", isDirectory: true) }
    public var sealedDirectory: URL { root.appendingPathComponent("sealed", isDirectory: true) }
    public var quarantineDirectory: URL { root.appendingPathComponent("quarantine", isDirectory: true) }

    public init(root: URL, platform: String = "ios") {
        self.root = root
        self.platform = platform
    }

    /// Appends records to the open file of frame `frameID`.
    public func appendOpen(spec: String, frameID: String, records: [AccelRecord]) throws {
        throw SensorStreamError.notImplemented
    }

    /// Compresses `records` as frame `frameID`, writes it to `sealed/`, and
    /// deletes the frame's open file.
    @discardableResult
    public func seal(spec: String, frameID: String, records: [AccelRecord]) throws -> SealedFrame {
        throw SensorStreamError.notImplemented
    }

    /// Seals every open file left by a previous run (for example, after a crash).
    @discardableResult
    public func recoverOpenFrames() throws -> [SealedFrame] {
        throw SensorStreamError.notImplemented
    }

    /// Returns the sealed frames, oldest `start_timestamp` first.
    public func sealedFrames() -> [SealedFrame] {
        []
    }

    /// Returns the quarantined frames.
    public func quarantinedFrames() -> [SealedFrame] {
        []
    }

    /// Reads a frame's compressed bytes.
    public func data(for frame: SealedFrame) throws -> Data {
        throw SensorStreamError.notImplemented
    }

    /// Deletes an uploaded frame.
    public func delete(_ frame: SealedFrame) throws {
        throw SensorStreamError.notImplemented
    }

    /// Moves a rejected frame to `quarantine/`.
    public func quarantine(_ frame: SealedFrame) throws {
        throw SensorStreamError.notImplemented
    }

    /// Deletes everything under the root (used on logout).
    public func removeAll() throws {
        throw SensorStreamError.notImplemented
    }
}
