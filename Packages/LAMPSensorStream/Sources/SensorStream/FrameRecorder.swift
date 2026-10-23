import Foundation

/// Connects a `FramePartitioner` to a `FrameStore` for one sensor spec:
/// appends the open frame to disk as it grows and seals every closed frame.
///
/// Call it from one serial queue.
public final class FrameRecorder {
    public let spec: String
    public let store: FrameStore
    public let partitioner: FramePartitioner

    /// The open frame's id and how many of its records are already on disk.
    private var persisted: (id: String, count: Int)?

    public init(spec: String, store: FrameStore, partitioner: FramePartitioner = FramePartitioner()) {
        self.spec = spec
        self.store = store
        self.partitioner = partitioner
    }

    /// Ingests one drained batch and applies the wall-clock close rule.
    /// Returns the frames sealed by this call.
    @discardableResult
    public func ingest(_ batch: [AccelRecord], nowMs: Int64) throws -> [SealedFrame] {
        var sealed = try seal(partitioner.append(batch))
        try persistOpenFrame()
        sealed += try seal(partitioner.closeExpired(nowMs: nowMs))
        return sealed
    }

    /// Seals the open frame (collector stop or clock session restart).
    @discardableResult
    public func closeOpenFrame() throws -> [SealedFrame] {
        guard let frame = partitioner.closeOpenFrame() else { return [] }
        return try seal([frame])
    }

    private func seal(_ frames: [PartitionedFrame]) throws -> [SealedFrame] {
        try frames.map { frame in
            if persisted?.id == frame.id { persisted = nil }
            return try store.seal(spec: spec, frameID: frame.id, records: frame.records)
        }
    }

    private func persistOpenFrame() throws {
        guard let open = partitioner.openFrame else { return }
        let alreadyOnDisk = persisted?.id == open.id ? persisted!.count : 0
        guard open.records.count > alreadyOnDisk else { return }
        try store.appendOpen(spec: spec, frameID: open.id, records: Array(open.records[alreadyOnDisk...]))
        persisted = (open.id, open.records.count)
    }
}
