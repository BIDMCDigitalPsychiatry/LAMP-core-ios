//
//  LMCommon.swift
//  lampv2
//
//  Created by ZCo Engineer on 14/01/20.
//

import Foundation
import HealthKit

protocol LampDataKeysProtocol {
    var jsonKey: String {get}
}
//extension LampDataKeysProtocol {
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.singleValueContainer()
//        try container.encode(jsonKey)
//    }
//}

extension HKQuantityTypeIdentifier: LampDataKeysProtocol {
    
    var jsonKey: String {
        switch self {
            
        case .bloodPressureSystolic:
            return "lamp.blood_pressure"
        case .bloodPressureDiastolic:
            return "lamp.blood_pressure"
        case .heartRate:
            return "lamp.heart_rate"
        case .height:
            return "lamp.height"
        case .respiratoryRate:
            return "lamp.respiratory_rate"
        case .bodyMass:
            return "lamp.weight"
        default:
            printDebug("vvvv" + self.rawValue)
            return self.rawValue
        }
    }
}


enum SensorType: LampDataKeysProtocol {

    case lamp_accelerometer
    case lamp_accelerometer_motion
    case lamp_analytics
    case lamp_blood_pressure
    case lamp_bluetooth
    case lamp_calls
    case lamp_distance
    case lamp_flights
    //case lamp_gps_contextual
    case lamp_gps
    case lamp_gyroscope
    case lamp_heart_rate
    case lamp_height
    case lamp_magnetometer
    case lamp_respiratory_rate
    case lamp_screen_state
    case lamp_segment
    case lamp_sleep
    case lamp_sms
    case lamp_steps
    case lamp_weight
    case lamp_wifi
    
    var jsonKey: String {
        switch self {
        case .lamp_accelerometer:
            return "lamp.accelerometer"
        case .lamp_accelerometer_motion:
            return "lamp.accelerometer.motion"
        case .lamp_analytics:
            return "lamp.analytics"
        case .lamp_blood_pressure:
            return "lamp.blood_pressure"
        case .lamp_bluetooth:
            return "lamp.bluetooth"
        case .lamp_calls:
            return "lamp.calls"
        case .lamp_distance:
            return "lamp.distance"
        case .lamp_flights:
            return "lamp.flights"
//        case .lamp_gps_contextual:
//            return "lamp.gps.contextual"
        case .lamp_gps:
            return "lamp.gps"
        case .lamp_gyroscope:
            return "lamp.gyroscope"
        case .lamp_heart_rate:
            return "lamp.heart_rate"
        case .lamp_height:
            return "lamp.height"
        case .lamp_magnetometer:
            return "lamp.magnetometer"
        case .lamp_respiratory_rate:
            return "lamp.respiratory_rate"
        case .lamp_screen_state:
            return "lamp.screen_state"
        case .lamp_segment:
            return "lamp.segment"
        case .lamp_sleep:
            return "lamp.sleep"
        case .lamp_sms:
            return "lamp.sms"
        case .lamp_steps:
            return "lamp.steps"
        case .lamp_weight:
            return "lamp.weight"
        case .lamp_wifi:
            return "lamp.wifi"
        }
    }
}
