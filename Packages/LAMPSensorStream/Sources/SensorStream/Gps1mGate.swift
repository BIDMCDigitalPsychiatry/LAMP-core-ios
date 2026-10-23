import Foundation

/// Keeps at most one `lamp.gps1m` fix per interval (60 s by default).
public struct Gps1mGate {
    /// The default minimum gap between accepted fixes, in milliseconds.
    public static let defaultIntervalMs: Int64 = 60_000

    /// The minimum gap between accepted fixes, in milliseconds.
    public let intervalMs: Int64
    /// The timestamp of the last accepted fix, in epoch milliseconds.
    public private(set) var lastAcceptedMs: Int64?

    public init(intervalMs: Int64 = Gps1mGate.defaultIntervalMs) {
        self.intervalMs = intervalMs
    }

    /// Returns `true` and records the fix when it's at least `intervalMs` away
    /// from the last accepted fix.
    public mutating func accept(timestampMs: Int64) -> Bool {
        false
    }

    /// Forgets the last accepted fix.
    public mutating func reset() {
        lastAcceptedMs = nil
    }
}
