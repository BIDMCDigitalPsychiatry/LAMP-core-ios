import Foundation

/// Converts sensor timestamps (seconds since boot, as in `CMLogItem.timestamp`)
/// to epoch milliseconds with one boot-to-epoch offset per session.
///
/// Uptime doesn't advance while the device sleeps, but the wall clock does, so
/// after a deep sleep (or an NTP or manual clock change) the drift check starts
/// a new session. Timestamps you already converted are never rewritten.
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
        offsetNs = Self.nanoseconds(wallEpochSeconds) - Self.nanoseconds(uptimeSeconds)
        session += 1
    }

    /// Returns `floor(epoch_ns / 1e6)` for a sensor timestamp, or `nil` before a session starts.
    public func epochMs(uptimeSeconds: Double) -> Int64? {
        guard let offsetNs = offsetNs else { return nil }
        return Self.floorDiv(Self.nanoseconds(uptimeSeconds) + offsetNs, 1_000_000)
    }

    /// Returns the wall clock minus the session's estimate of it, in milliseconds.
    public func driftMs(wallEpochSeconds: Double, uptimeSeconds: Double) -> Int64? {
        guard let offsetNs = offsetNs else { return nil }
        let estimateNs = Self.nanoseconds(uptimeSeconds) + offsetNs
        return (Self.nanoseconds(wallEpochSeconds) - estimateNs) / 1_000_000
    }

    /// Starts a new session when the drift exceeds `maxDriftMs`, and returns
    /// `true` if it did. Close the open frame before you convert more samples.
    public mutating func restartIfDrifted(wallEpochSeconds: Double, uptimeSeconds: Double) -> Bool {
        guard let drift = driftMs(wallEpochSeconds: wallEpochSeconds, uptimeSeconds: uptimeSeconds),
              abs(drift) > Self.maxDriftMs else { return false }
        startSession(wallEpochSeconds: wallEpochSeconds, uptimeSeconds: uptimeSeconds)
        return true
    }

    private static func nanoseconds(_ seconds: Double) -> Int64 {
        Int64((seconds * 1_000_000_000).rounded())
    }

    private static func floorDiv(_ a: Int64, _ b: Int64) -> Int64 {
        let q = a / b
        return (a % b != 0 && (a < 0) != (b < 0)) ? q - 1 : q
    }
}
