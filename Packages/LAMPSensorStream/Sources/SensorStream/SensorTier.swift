import Foundation

/// Sampling settings for one accelerometer tier.
public struct SensorTier: Equatable {
    /// How often you drain the motion buffer into the frame store, in seconds.
    public static let drainInterval: TimeInterval = 5.0

    /// The tier's sensor spec.
    public let key: SensorStreamKey
    /// The nominal sampling rate, in hertz.
    public let nominalHz: Int
    /// The value for `CMMotionManager.accelerometerUpdateInterval`, in seconds.
    public let accelerometerUpdateInterval: TimeInterval

    /// The tier's spec string, for example `lamp.accelerometer50hz`.
    public var spec: String { key.rawValue }

    /// The nominal number of records in one 5-minute window.
    public var nominalSamplesPerWindow: Int {
        nominalHz * Int(FramePartitioner.windowMs / 1_000)
    }

    /// All four tiers, slowest first.
    public static let all: [SensorTier] = [
        SensorTier(key: .accelerometer10hz, nominalHz: 10, accelerometerUpdateInterval: 0.1),
        SensorTier(key: .accelerometer20hz, nominalHz: 20, accelerometerUpdateInterval: 0.05),
        SensorTier(key: .accelerometer50hz, nominalHz: 50, accelerometerUpdateInterval: 0.02),
        SensorTier(key: .accelerometer100hz, nominalHz: 100, accelerometerUpdateInterval: 0.01),
    ]

    private init(key: SensorStreamKey, nominalHz: Int, accelerometerUpdateInterval: TimeInterval) {
        self.key = key
        self.nominalHz = nominalHz
        self.accelerometerUpdateInterval = accelerometerUpdateInterval
    }

    /// Creates the tier for an accelerometer spec, or returns `nil` for any other spec.
    public init?(spec: String) {
        guard let tier = SensorTier.all.first(where: { $0.spec == spec }) else { return nil }
        self = tier
    }

    /// Returns the fastest tier among `specs`, or `nil` when none is configured.
    public static func highestConfigured(in specs: [String]) -> SensorTier? {
        specs.compactMap(SensorTier.init(spec:)).max { $0.nominalHz < $1.nominalHz }
    }
}
