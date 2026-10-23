import Foundation

/// Converts sensor timestamps (seconds since boot, as in `CMLogItem.timestamp`)
/// to epoch milliseconds with one boot-to-epoch offset per session.
public struct SensorClock {
    /// The largest drift, in milliseconds, that a session tolerates.
    public static let maxDriftMs: Int64 = 1_000

    /// Epoch nanoseconds minus uptime nanoseconds, fixed for the session.
    public private(set) var offsetNs: Int64?
    /// Increments every time a session starts.
    public private(set) var session: Int = 0

    public init() {}

    /// Starts a session and captures the offset from the current wall clock and uptime.
    public mutating func startSession(wallEpochSeconds: Double, uptimeSeconds: Double) {
    }

    /// Returns `floor(epoch_ns / 1e6)` for a sensor timestamp, or `nil` before a session starts.
    public func epochMs(uptimeSeconds: Double) -> Int64? {
        nil
    }

    /// Returns the wall clock minus the session's estimate of it, in milliseconds.
    public func driftMs(wallEpochSeconds: Double, uptimeSeconds: Double) -> Int64? {
        nil
    }

    /// Starts a new session when the drift exceeds `maxDriftMs`, and returns
    /// `true` if it did. Close the open frame before you convert more samples.
    public mutating func restartIfDrifted(wallEpochSeconds: Double, uptimeSeconds: Double) -> Bool {
        false
    }
}
