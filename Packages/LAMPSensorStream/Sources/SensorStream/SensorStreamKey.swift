import Foundation

/// The five sensor specs that this package handles.
public enum SensorStreamKey: String, CaseIterable {
    case gps1m = "lamp.gps1m"
    case accelerometer10hz = "lamp.accelerometer10hz"
    case accelerometer20hz = "lamp.accelerometer20hz"
    case accelerometer50hz = "lamp.accelerometer50hz"
    case accelerometer100hz = "lamp.accelerometer100hz"

    /// The legacy 5 Hz JSON accelerometer spec from LAMP-swift.
    public static let legacyAccelerometer = "lamp.accelerometer"
    /// The legacy JSON GPS spec from LAMP-swift.
    public static let legacyGPS = "lamp.gps"

    /// `true` for the four binary accelerometer tiers.
    public var isAccelerometerTier: Bool {
        self != .gps1m
    }

    /// The four accelerometer tiers, slowest first.
    public static var accelerometerTiers: [SensorStreamKey] {
        allCases.filter(\.isAccelerometerTier)
    }
}
