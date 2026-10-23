import Foundation

/// The frame that's still collecting records.
public struct OpenFrame: Equatable {
    public let id: String
    public let window: Int64
    /// Records in arrival order.
    public internal(set) var records: [AccelRecord]
}

/// A closed frame, ready to compress.
public struct PartitionedFrame: Equatable {
    public let id: String
    public let window: Int64
    /// Records, stable-sorted by timestamp.
    public let records: [AccelRecord]
    /// `true` when the records arrived after their window was closed.
    public let late: Bool

    public var startTimestamp: Int64 { records.first?.timestamp ?? 0 }
    public var endTimestamp: Int64 { records.last?.timestamp ?? 0 }
}

/// Splits delivered batches into 5-minute frames and applies the contract's
/// close rules. It never drops a record.
public final class FramePartitioner {
    /// The window length, in milliseconds.
    public static let windowMs: Int64 = 300_000
    /// Maximum report latency plus margin, in milliseconds.
    public static let closeGraceMs: Int64 = 15_000
    /// The most records a frame may hold (`sample_count` limit).
    public static let maxRecordsPerFrame = 66_000

    /// Returns `floor(timestamp / 300000)`.
    public static func window(of timestamp: Int64) -> Int64 {
        0
    }

    /// Returns the wall-clock time at which window `window`'s frame closes.
    public static func closeDeadline(forWindow window: Int64) -> Int64 {
        0
    }

    public private(set) var openFrame: OpenFrame?

    public init() {}

    /// Routes a batch, record by record, and returns the frames it closed,
    /// followed by late partial frames.
    public func append(_ batch: [AccelRecord]) -> [PartitionedFrame] {
        []
    }

    /// Closes the open frame if the wall clock passed its deadline.
    public func closeExpired(nowMs: Int64) -> [PartitionedFrame] {
        []
    }

    /// Closes the open frame because the collector stopped or the clock
    /// session restarted. Later records for the same window open a new frame.
    public func closeOpenFrame() -> PartitionedFrame? {
        nil
    }
}
