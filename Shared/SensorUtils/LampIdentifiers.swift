// mindLAMP

import Foundation


protocol LampDataKeysProtocol {
    var jsonKey: String {get}
}

enum SensorType: LampDataKeysProtocol {
    
    case lamp_accelerometer
    case lamp_accelerometer_motion
    case lamp_analytics
    case lamp_bluetooth
    case lamp_calls
    case lamp_distance
    case lamp_flights_up
    case lamp_flights_down
    case lamp_currentPace
    case lamp_currentCadence
    case lamp_avgActivePace
    case lamp_gps
    case lamp_gyroscope
    case lamp_magnetometer
    case lamp_screen_state
    case lamp_segment
    case lamp_sms
    case lamp_steps
    case lamp_wifi
    
    case lamp_watch_accelerometer
    case lamp_watch_accelerometer_motion
    
    var jsonKey: String {
        switch self {
        case .lamp_accelerometer:
            return "lamp.accelerometer"
        case .lamp_accelerometer_motion:
            return "lamp.accelerometer.motion"
        case .lamp_analytics:
            return "lamp.analytics"
        case .lamp_bluetooth:
            return "lamp.bluetooth"
        case .lamp_calls:
            return "lamp.calls"
        case .lamp_distance:
            return "lamp.distance"
        case .lamp_flights_up:
            return "lamp.floors_ascended"
        case .lamp_flights_down:
            return "lamp.floors_descended"
        case .lamp_gps:
            return "lamp.gps"
        case .lamp_gyroscope:
            return "lamp.gyroscope"
        case .lamp_magnetometer:
            return "lamp.magnetometer"
        case .lamp_screen_state:
            return "lamp.screen_state"
        case .lamp_segment:
            return "lamp.segment"
        case .lamp_sms:
            return "lamp.sms"
        case .lamp_steps:
            return "lamp.steps"
        case .lamp_wifi:
            return "lamp.wifi"
        case .lamp_currentPace:
            return "lamp.current_pace"
        case .lamp_currentCadence:
            return "lamp.current_cadence"
        case .lamp_avgActivePace:
            return "lamp.avg_active_pace"
        case .lamp_watch_accelerometer:
            return "lamp.watch.accelerometer"
        case .lamp_watch_accelerometer_motion:
            return "lamp.watch.accelerometer.motion"
        }
    }
}
