import Foundation

/// Sampling settings for one accelerometer tier.
public struct SensorTier: Equatable {
    /// How often you drain the motion buffer into the frame store, in seconds.
    public static let drainInterval: TimeInterval = 0

    /// The tier's sensor spec.
    public let key: SensorStreamKey
    /// The nominal sampling rate, in hertz.
    public let nominalHz: Int
    /// The value for `CMMotionManager.accelerometerUpdateInterval`, in seconds.
    public let accelerometerUpdateInterval: TimeInterval

    /// The tier's spec string, for example `lamp.accelerometer50hz`.
    public var spec: String { key.rawValue }

    /// The nominal number of records in one 5-minute window.
    public var nominalSamplesPerWindow: Int { 0 }

    /// All four tiers, slowest first.
    public static let all: [SensorTier] = []

    /// Creates the tier for an accelerometer spec, or returns `nil` for any other spec.
    public init?(spec: String) {
        return nil
    }

    /// Returns the fastest tier among `specs`, or `nil` when none is configured.
    public static func highestConfigured(in specs: [String]) -> SensorTier? {
        nil
    }
}
