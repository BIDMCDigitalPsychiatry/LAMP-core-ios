//
//  SensorModel.swift
//  mindLAMP Consortium
//
//  Created by ZCO Engineer on 13/01/20.
//

import Foundation

protocol TextPresentation {
    var stringValue: String? {get}
}

enum SensorData {

    struct Request {
        var sensorEvents: [SensorDataInfo]
    }
    
    struct Response: Decodable {
    }

}

extension SensorData.Request: Encodable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(sensorEvents)
    }
}

struct SensorDataInfo: Encodable {
    var sensor: String
    var timestamp: Double
    var data: SensorDataModel
}

struct SensorDataModel: Encodable {
    
    //Triaxial Values for: Accelerometer, Magnetometer, Gyroscope
    var x: Double?
    var y: Double?
    var z: Double?

    var motion: Motion?
    var gravity: Gravitational?
    var magnetic: Magnetic?
    var rotation: Rotational?
    var attitude: Attitude?
    //Health
    var unit: String?
    var value: Double?
    var valueString: String?
    var bp_diastolic: Double?
    var bp_systolic: Double?
    var workout_type: String?
    var workout_durtion: Double?
    //Location
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    //Bluetooth
    var bt_rssi: Int?
    var bt_name: String?
    var bt_address: String?
    //Wifi
    var bssid: String?
    var ssid: String?
    //Pedometer
    //var steps: Int?
    //var flights_climbed: Int?
    //var distance: Double?
    //Screen State
    //var state: Int?
    //Calls
    var call_duration: Double?
    var call_type: Int?
    var call_trace: String?
    
    var startDate: Double?
    var endDate: Double?
}

struct Motion: Encodable {
    var x: Double?
    var y: Double?
    var z: Double?
}

struct Rotational: Encodable {
    var x: Double?
    var y: Double?
    var z: Double?
}

struct Gravitational: Encodable {
    var x: Double?
    var y: Double?
    var z: Double?
}

struct Attitude: Encodable {
    var roll: Double?
    var pitch: Double?
    var yaw: Double?
}

struct Magnetic: Encodable {
    var x: Double?
    var y: Double?
    var z: Double?
}

enum ScreenState: Int {
    
    case screen_on
    case screen_off
    case screen_locked
    case screen_unlocked
}

extension ScreenState: TextPresentation {
    var stringValue: String? {
    switch self {
    
    case .screen_on:
        return "Screen On"
    case .screen_off:
        return "Screen Off"
    case .screen_locked:
        return "Screen Locked"
    case .screen_unlocked:
        return "Screen Unlocked"
        }
    }
}

struct ScreenStateData {
    
    var screenState: ScreenState = .screen_on
    var timestamp: Double = Date().timeInMilliSeconds
}
