//  mindLAMP Consortium

#if os(iOS)
import CoreLocation
import Foundation
import LAMP
import SensorStream

/// Collects `lamp.gps1m`: continuous best-accuracy location updates, thinned
/// to at most one fix per 60 s by `Gps1mGate`. Fixes are buffered as JSON
/// `SensorEvent`s with the `lamp.gps` data shape and leave through the
/// existing `SensorLogs` path with the other sensors.
///
/// It relies on the location authorization that `LocationsSensor` requests.
final class Gps1mCollector: NSObject {

    /// Cached fixes older than this are skipped, in seconds.
    static let maxFixAge: TimeInterval = 60

    private let manager = CLLocationManager()
    private let lock = NSLock()
    private var gate = Gps1mGate()
    private var events: [SensorEvent<SensorDataModel>] = []

    /// Starts updates. Call it on the main thread.
    func start() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.delegate = nil
    }

    /// Returns the buffered events and empties the buffer.
    func drainEvents() -> [SensorEvent<SensorDataModel>] {
        lock.lock()
        defer { lock.unlock() }
        let drained = events
        events.removeAll()
        return drained
    }

    /// Applies the gate and buffers accepted fixes.
    func handle(_ locations: [CLLocation], now: Date = Date()) {
        let sorted = locations.sorted { $0.timestamp < $1.timestamp }
        lock.lock()
        defer { lock.unlock() }
        for location in sorted where location.horizontalAccuracy >= 0
            && abs(location.timestamp.timeIntervalSince(now)) <= Self.maxFixAge {
            let timestampMs = Int64((location.timestamp.timeIntervalSince1970 * 1_000).rounded(.down))
            guard gate.accept(timestampMs: timestampMs) else { continue }
            var model = SensorDataModel()
            model.latitude = location.coordinate.latitude
            model.longitude = location.coordinate.longitude
            model.altitude = location.altitude
            model.accuracy = location.horizontalAccuracy
            events.append(SensorEvent(timestamp: Double(timestampMs), sensor: SensorStreamKey.gps1m.rawValue, data: model))
        }
    }
}

extension Gps1mCollector: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        handle(locations)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        printToFile("gps1m location error: \(error.localizedDescription)")
    }
}
#endif
