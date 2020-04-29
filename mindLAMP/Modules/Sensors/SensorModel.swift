//
//  SensorModel.swift
//  lampv2
//
//  Created by ZCO Engineer on 13/01/20.
//

import Foundation

enum SensorData {

    struct Request: Encodable {
        var timestamp: Double
        var sensor: SensorType
        var data: SensorDataModel
    }
    
    struct Response: Decodable {
    }
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
    //Health
    var unit: String?
    var value: Double?
    var bp_diastolic: Int?
    var bp_systolic: Int?
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
    var steps: Int?
    var flights_climbed: Int?
    var distance: Double?
    //Screen State
    var state: Int?
    //Calls
    var call_duration: Double?
    var call_type: Int?
    var call_trace: String?
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

struct ScreenStateData {
    
    var screenState: ScreenState = .screen_on
    var timestamp: Double = Date.currentTimeSince1970()
}
