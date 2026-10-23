import Foundation

/// Converts CoreMotion acceleration (g, iOS sign) to the contract's units
/// (m/s², Android sign). Face up, iOS reads `(0, 0, -1)` and the record holds
/// `(0, 0, +9.80665)`.
public enum UnitConversion {
    /// Standard gravity, in m/s².
    public static let standardGravity = 9.80665

    /// Returns `value * -9.80665` as a `Float`. A zero axis becomes `-0.0`.
    public static func metersPerSecondSquared(fromG value: Double) -> Float {
        Float(value * -standardGravity)
    }

    /// Builds a record from a CoreMotion sample.
    public static func record(timestamp: Int64, xG: Double, yG: Double, zG: Double) -> AccelRecord {
        AccelRecord(timestamp: timestamp,
                    x: metersPerSecondSquared(fromG: xG),
                    y: metersPerSecondSquared(fromG: yG),
                    z: metersPerSecondSquared(fromG: zG))
    }
}
