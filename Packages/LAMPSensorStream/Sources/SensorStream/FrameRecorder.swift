import Foundation

/// Connects a `FramePartitioner` to a `FrameStore` for one sensor spec:
/// appends the open frame to disk as it grows and seals every closed frame.
public final class FrameRecorder {
    public let spec: String
    public let store: FrameStore
    public let partitioner: FramePartitioner

    public init(spec: String, store: FrameStore, partitioner: FramePartitioner = FramePartitioner()) {
        self.spec = spec
        self.store = store
        self.partitioner = partitioner
    }

    /// Ingests one drained batch and applies the wall-clock close rule.
    /// Returns the frames sealed by this call.
    @discardableResult
    public func ingest(_ batch: [AccelRecord], nowMs: Int64) throws -> [SealedFrame] {
        throw SensorStreamError.notImplemented
    }

    /// Seals the open frame (collector stop or clock session restart).
    @discardableResult
    public func closeOpenFrame() throws -> [SealedFrame] {
        throw SensorStreamError.notImplemented
    }
}
