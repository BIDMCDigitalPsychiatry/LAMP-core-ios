import Foundation

/// Converts CoreMotion acceleration (g, iOS sign) to the contract's units
/// (m/s², Android sign).
public enum UnitConversion {
    /// Standard gravity, in m/s².
    public static let standardGravity = 9.80665

    /// Returns `value * -9.80665` as a `Float`.
    public static func metersPerSecondSquared(fromG value: Double) -> Float {
        0
    }

    /// Builds a record from a CoreMotion sample.
    public static func record(timestamp: Int64, xG: Double, yG: Double, zG: Double) -> AccelRecord {
        AccelRecord(timestamp: 0, x: 0, y: 0, z: 0)
    }
}
