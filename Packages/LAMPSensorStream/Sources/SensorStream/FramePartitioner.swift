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
///
/// - A record from a later window closes the open frame.
/// - The wall clock reaching `(k + 1) * 300000 + 15000` closes window `k`.
/// - `closeOpenFrame()` closes the frame when the collector stops or the
///   clock session restarts; later records for that window open a new frame.
/// - A record for a window that's already closed becomes part of a late
///   partial frame, which is returned (closed) at the end of its batch.
/// - A frame that reaches 66,000 records closes, and the window continues in
///   a new frame, so `sample_count` never exceeds the server's limit.
public final class FramePartitioner {
    /// The window length, in milliseconds.
    public static let windowMs: Int64 = 300_000
    /// Maximum report latency plus margin, in milliseconds.
    public static let closeGraceMs: Int64 = 15_000
    /// The most records a frame may hold (`sample_count` limit).
    public static let maxRecordsPerFrame = 66_000

    /// Returns `floor(timestamp / 300000)`.
    public static func window(of timestamp: Int64) -> Int64 {
        let q = timestamp / windowMs
        return (timestamp % windowMs != 0 && timestamp < 0) ? q - 1 : q
    }

    /// Returns the wall-clock time at which window `window`'s frame closes.
    public static func closeDeadline(forWindow window: Int64) -> Int64 {
        (window + 1) * windowMs + closeGraceMs
    }

    public private(set) var openFrame: OpenFrame?
    /// The newest window closed by a later record or by its deadline.
    private var highestClosedWindow: Int64?

    public init() {}

    /// Routes a batch, record by record, and returns the frames it closed,
    /// followed by late partial frames (one per window, oldest first).
    public func append(_ batch: [AccelRecord]) -> [PartitionedFrame] {
        var closed: [PartitionedFrame] = []
        var late: [Int64: [AccelRecord]] = [:]
        for record in batch {
            let window = Self.window(of: record.timestamp)
            if let open = openFrame {
                if window == open.window {
                    appendToOpen(record, closed: &closed)
                } else if window > open.window {
                    closed.append(close(open, late: false))
                    markClosed(open.window)
                    openNew(window: window, with: record)
                } else {
                    late[window, default: []].append(record)
                }
            } else if let highest = highestClosedWindow, window <= highest {
                late[window, default: []].append(record)
            } else {
                openNew(window: window, with: record)
            }
        }
        for window in late.keys.sorted() {
            // A late frame can't exceed the limit either; split it the same way.
            let records = late[window]!
            for start in stride(from: 0, to: records.count, by: Self.maxRecordsPerFrame) {
                let chunk = Array(records[start..<min(start + Self.maxRecordsPerFrame, records.count)])
                closed.append(PartitionedFrame(id: Self.newID(window), window: window,
                                               records: AccelRecordPacker.stableSorted(chunk), late: true))
            }
        }
        return closed
    }

    /// Closes the open frame if the wall clock passed its deadline.
    public func closeExpired(nowMs: Int64) -> [PartitionedFrame] {
        guard let open = openFrame, nowMs >= Self.closeDeadline(forWindow: open.window) else { return [] }
        openFrame = nil
        markClosed(open.window)
        return [close(open, late: false)]
    }

    /// Closes the open frame because the collector stopped or the clock
    /// session restarted. Later records for the same window open a new frame.
    public func closeOpenFrame() -> PartitionedFrame? {
        guard let open = openFrame else { return nil }
        openFrame = nil
        return close(open, late: false)
    }

    private func appendToOpen(_ record: AccelRecord, closed: inout [PartitionedFrame]) {
        guard var open = openFrame else { return }
        if open.records.count >= Self.maxRecordsPerFrame {
            closed.append(close(open, late: false))
            openNew(window: open.window, with: record)
            return
        }
        openFrame = nil  // Drop the stored copy first so the append doesn't copy the array.
        open.records.append(record)
        openFrame = open
    }

    private func openNew(window: Int64, with record: AccelRecord) {
        openFrame = OpenFrame(id: Self.newID(window), window: window, records: [record])
    }

    private func markClosed(_ window: Int64) {
        highestClosedWindow = max(highestClosedWindow ?? window, window)
    }

    private func close(_ frame: OpenFrame, late: Bool) -> PartitionedFrame {
        PartitionedFrame(id: frame.id, window: frame.window,
                         records: AccelRecordPacker.stableSorted(frame.records), late: late)
    }

    private static func newID(_ window: Int64) -> String {
        "\(window)-\(UUID().uuidString.lowercased())"
    }
}
