//
//  SensorModel.swift
//  mindLAMP Consortium
//
//  Created by ZCO Engineer on 13/01/20.
//

import Foundation

enum SensorData {

    struct Request {
        var sensorEvents: [SensorDataInfo]
    }
    
    struct Response: Decodable {
    }

}

extension SensorData.Request: Codable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(sensorEvents)
    }
    
    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            sensorEvents = try container.decode([SensorDataInfo].self)
        } catch {
            assertionFailure("ERROR: \(error)")
            sensorEvents = []
        }
    }
}

struct SensorDataInfo: Codable {
    var sensor: String
    var timestamp: Double
    var data: SensorDataModel
}

struct SensorDataModel: Codable {
    
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
    var workout_duration: Double?
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

struct Motion: Codable {
    var x: Double?
    var y: Double?
    var z: Double?
}

struct Rotational: Codable {
    var x: Double?
    var y: Double?
    var z: Double?
}

struct Attitude: Codable {
    var roll: Double?
    var pitch: Double?
    var yaw: Double?
}

struct Gravitational: Codable {
    var x: Double?
    var y: Double?
    var z: Double?
}

struct Magnetic: Codable {
    var x: Double?
    var y: Double?
    var z: Double?
}
