// mindLAMP

import Foundation

public protocol LampDataKeysProtocol {
    var lampIdentifier: String {get}
}

public enum SensorType: LampDataKeysProtocol {
    
    enum AnalyticAction: String {
        case login = "login"
        case notification = "notification"
        case logout = "logout"
    }

    
    //Other sensor data
    case lamp_analytics
    case lamp_bluetooth
    case lamp_calls
    case lamp_gps
    case lamp_gyroscope
    case lamp_magnetometer
    case lamp_screen_state
    case lamp_segment
    case lamp_sms
    case lamp_wifi
    
    //CMPedometerData
    case lamp_flights_up
    case lamp_flights_down
    case lamp_currentPace
    case lamp_currentCadence
    case lamp_avgActivePace
    case lamp_distance
    case lamp_steps
    
    //Motion data
    case lamp_accelerometer
    case lamp_accelerometer_motion
    
    public var lampIdentifier: String {
        switch self {
        case .lamp_accelerometer:
            #if os(watchOS)
                return "lamp.watch.accelerometer"
            #else
                return "lamp.accelerometer"
            #endif
        case .lamp_accelerometer_motion:
            #if os(watchOS)
                return "lamp.watch.accelerometer.motion"
            #else
            return "lamp.accelerometer.motion"
            #endif
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
            #if os(watchOS)
                return "lamp.watch.gps"
            #else
                return "lamp.gps"
            #endif
        case .lamp_gyroscope:
            #if os(watchOS)
                return "lamp.watch.gyroscope"
            #else
                return "lamp.gyroscope"
            #endif
        case .lamp_magnetometer:
            #if os(watchOS)
                return "lamp.watch.magnetometer"
            #else
                return "lamp.magnetometer"
            #endif
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
        }
    }
}
