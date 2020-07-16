// watchkitapp Extension

import Foundation

enum WatchSensorType {
    
    case lamp_accelerometer
    case lamp_accelerometer_motion
    case lamp_analytics
    
    var jsonKey: String {
        switch self {
        case .lamp_accelerometer:
            return "lamp.accelerometer"
        case .lamp_accelerometer_motion:
            return "lamp.accelerometer.motion"
        case .lamp_analytics:
            return "lamp.watch.analytics"
//        case .lamp_bluetooth:
//            return "lamp.bluetooth"
//        case .lamp_calls:
//            return "lamp.calls"
//        case .lamp_distance:
//            return "lamp.distance"
//        case .lamp_flights_up:
//            return "lamp.floors_ascended"
//        case .lamp_flights_down:
//            return "lamp.floors_descended"
//        case .lamp_gps:
//            return "lamp.gps"
//        case .lamp_gyroscope:
//            return "lamp.gyroscope"
//        case .lamp_magnetometer:
//            return "lamp.magnetometer"
//        case .lamp_screen_state:
//            return "lamp.screen_state"
//        case .lamp_segment:
//            return "lamp.segment"
//        case .lamp_sms:
//            return "lamp.sms"
//        case .lamp_steps:
//            return "lamp.steps"
//        case .lamp_wifi:
//            return "lamp.wifi"
//        case .lamp_currentPace:
//            return "lamp.current_pace"
//        case .lamp_currentCadence:
//            return "lamp.current_cadence"
//        case .lamp_avgActivePace:
//            return "lamp.avg_active_pace"
        }
    }
}
