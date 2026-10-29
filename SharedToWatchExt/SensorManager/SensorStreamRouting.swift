//  mindLAMP Consortium

#if os(iOS)
import Foundation
import SensorStream

/// Decides which collectors run for the configured sensor specs.
///
/// Precedence rules:
/// - When several accelerometer tiers are configured, only the fastest runs.
/// - Any accelerometer tier replaces the legacy 5 Hz `lamp.accelerometer`
///   JSON stream, so two `CMMotionManager` streams never compete for the
///   hardware. `lamp.device_motion` is unaffected.
/// - `lamp.gps1m` runs alongside `lamp.gps`; each keeps its own spec.
struct SensorStreamRouting: Equatable {
    /// The accelerometer tier to record, if any.
    let accelerometerTier: SensorTier?
    /// Configured tiers that lost to a faster tier.
    let ignoredAccelerometerSpecs: [String]
    /// Whether the legacy `lamp.accelerometer` JSON stream runs.
    let runsLegacyAccelerometer: Bool
    /// Whether the legacy `lamp.gps` JSON stream collects data.
    let collectsLegacyGPS: Bool
    /// Whether the `lamp.gps1m` collector runs.
    let runsGps1m: Bool

    /// The spec of the tier to record, for example `lamp.accelerometer50hz`.
    var accelerometerSpec: String? { accelerometerTier?.spec }

    init(specs: [String]) {
        let winner = SensorTier.highestConfigured(in: specs)
        accelerometerTier = winner
        ignoredAccelerometerSpecs = SensorTier.all
            .filter { $0 != winner && specs.contains($0.spec) }
            .map(\.spec)
        runsLegacyAccelerometer = winner == nil && specs.contains(SensorStreamKey.legacyAccelerometer)
        collectsLegacyGPS = specs.contains(SensorStreamKey.legacyGPS)
        runsGps1m = specs.contains(SensorStreamKey.gps1m.rawValue)
    }
}
#endif
