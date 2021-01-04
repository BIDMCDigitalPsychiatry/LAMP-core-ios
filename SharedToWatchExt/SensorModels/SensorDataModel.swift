//
//  SensorModel.swift
//  mindLAMP Consortium
//
//  Created by ZCO Engineer on 13/01/20.
//

import Foundation
import CoreMotion
import LAMP

public enum SensorData {

    public struct Request {
        public var sensorEvents: [SensorEvent<SensorDataModel>]
        public init(sensorEvents: [SensorEvent<SensorDataModel>]) {
            self.sensorEvents = sensorEvents
        }
    }
    
    public struct Response: Decodable {
    }
}

extension SensorData.Request: Codable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(sensorEvents)
    }
    
    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            sensorEvents = try container.decode([SensorEvent<SensorDataModel>].self)
        } catch {
            assertionFailure("ERROR: \(error)")
            sensorEvents = []
        }
    }
}

public struct UserAgent {
    var model: String
    var os_version: String
    var app_version: String
    public init(model: String, os_version: String, app_version: String) {
        self.model = model
        self.os_version = os_version
        self.app_version = app_version
    }
}

extension UserAgent {
    public func toString() -> String {
        return "\(app_version), \(model), \(os_version)"
    }
}

public struct PayLoadInfo {
    var action: String
    var device_type: String// = "iOS" //"Android" or "Web"
    var user_agent: UserAgent?
    var payload: [String: Any]?
    public init(action: String, userInfo: [AnyHashable: Any], userAgent: UserAgent?) {
        self.action = action
        self.user_agent = userAgent
        self.device_type = DeviceType.displayName
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted)
            //let jsonString = String(bytes: jsonData, encoding: String.Encoding.utf8) ?? ""
            let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
            // you can now cast it with the right type
            if let dictFromJSON = decoded as? [String: Any] {
                payload = dictFromJSON
            }
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    public func toJSON() -> [String: Any] {
        return ["action": action,
                "content": payload ?? NSNull(),
                "device_type": device_type,
                "user_agent": user_agent?.toString() ?? NSNull()
        ]
    }
}

public struct UpdateReadRequest {
    var timestamp: UInt64
    var sensor: String
    var data: PayLoadInfo
    
    public init(timeInterval: TimeInterval, sensor: String, payLoadInfo: PayLoadInfo) {
        data = payLoadInfo
        timestamp = UInt64(timeInterval * 1000)
        self.sensor = sensor
    }
    public func toJSON() -> [String: Any] {
        return ["timestamp": timestamp,
                "sensor" : sensor,
                "data": data.toJSON()
        ]
    }
}

public struct DeviceInfoWithToken: Codable {
    
    var action: String? //SensorType.AnalyticAction.login.rawValue
    var device_type: String// = "iOS" //"Android" or "Web"
    var user_agent: String?
    var device_token: String?
    
    public init(deviceToken: String?, userAgent: UserAgent?, action: String?) {
        self.action = action
        self.device_token = deviceToken
        self.user_agent = userAgent?.toString()
        self.device_type = DeviceType.displayName
    }
}

public struct SensorDataModel: Codable {
    
    public init(){}
    public var source: String?
    //Triaxial Values for: Accelerometer, Magnetometer, Gyroscope
    public var x: Double?
    public var y: Double?
    public var z: Double?

    public var motion: Motion?
    public var gravity: Gravitational?
    public var magnetic: Magnetic?
    public var rotation: Rotational?
    public var attitude: Attitude?
    public var activity: SensorActivity?
    
    //Health
    public var unit: String?
    public var value: Double?
    public var valueString: String?
    public var bp_diastolic: Double?
    public var bp_systolic: Double?
    public var workout_type: String?
    public var workout_duration: Double?
    //Location
    public var latitude: Double?
    public var longitude: Double?
    public var altitude: Double?
    //Bluetooth
    public var bt_rssi: Int?
    public var bt_name: String?
    public var bt_address: String?
    //Wifi
    public var bssid: String?
    public var ssid: String?
    //Pedometer
    //var steps: Int?
    //var flights_climbed: Int?
    //var distance: Double?
    //Screen State
    //var state: Int?
    //Calls
    public var call_duration: Double?
    public var call_type: Int?
    public var call_trace: String?
    
    public var startDate: Double?
    public var endDate: Double?
    
    enum CodingKeys: String, CodingKey {
        
        case source
        
        case x
        case y
        case z
        case motion
        case gravity
        case magnetic
        case rotation
        case attitude
        
        case activity
        //Health
//        var unit: String?
        case value
        case valueString
        case bp_diastolic
        case bp_systolic
        case workout_type
        case workout_duration
        //Location
        case latitude
        case longitude
        case altitude
        //Bluetooth
        case bt_rssi
        case bt_name
        case bt_address
        //Wifi
        case bssid
        case ssid
        //Pedometer
        //Calls
        case call_duration
        case call_type
        case call_trace
//
//        var startDate: Double?
//        var endDate: Double?
    }
}

public struct Motion: Codable {
    var x: Double?
    var y: Double?
    var z: Double?
}

public struct Rotational: Codable {
    var x: Double?
    var y: Double?
    var z: Double?
}

public struct Attitude: Codable {
    var roll: Double?
    var pitch: Double?
    var yaw: Double?
}

public struct Gravitational: Codable {
    var x: Double?
    var y: Double?
    var z: Double?
}

public struct Magnetic: Codable {
    var x: Double?
    var y: Double?
    var z: Double?
}

public struct SensorActivity: Codable {
    var stationary: Bool?
    var walking: Bool?
    var running: Bool?
    var in_car: Bool?
    var cycling: Bool?
    var unknown: Bool?
    
    //var start_date: UInt64?
    var confidence: Double?
}

extension SensorDataModel {

    public init(screenData: ScreenStateData) {
        self.value = Double(screenData.screenState.rawValue)
        self.valueString = screenData.screenState.stringValue
    }
    
    public init(callsData: CallsData) {
        self.call_type = callsData.type
        self.call_duration = Double(callsData.duration)
        self.call_trace = callsData.trace
    }
    
    public init(locationData: LocationsData) {
        self.latitude = locationData.latitude
        self.longitude = locationData.longitude
        self.altitude = locationData.altitude
    }
    
    public init(motionData: MotionData) {
        
        //User Acceleration
        let motion = Motion(x: motionData.acceleration.x, y: motionData.acceleration.y, z: motionData.acceleration.z)
        self.motion = motion
        
        //Gravity
        let gravity = Gravitational(x: motionData.gravity.x, y: motionData.gravity.y, z: motionData.gravity.z)
        self.gravity = gravity
        
        //Gyro
        let rotation = Rotational(x: motionData.rotationRate.x, y: motionData.rotationRate.y, z: motionData.rotationRate.z)
        self.rotation = rotation

        //MageticField
//      let magnetic = Magnetic(x: motionData.magneticField.x, y: motionData.magneticField.y, z: motionData.magneticField.z)
//      self.magnetic = magnetic
        
        //Attitude
        let attitude = Attitude(roll: motionData.deviceAttitude.roll, pitch: motionData.deviceAttitude.pitch, yaw: motionData.deviceAttitude.yaw)
        self.attitude = attitude
    }
}

extension SensorDataModel {

    public init(rotationRate: CMRotationRate) {
        self.x = rotationRate.x
        self.y = rotationRate.y
        self.z = rotationRate.z
    }
    
    public init(accelerationRate: CMAcceleration) {
        self.x = accelerationRate.x
        self.y = accelerationRate.y
        self.z = accelerationRate.z
    }
    
    public init(magneticField: CMMagneticField) {
        self.x = magneticField.x
        self.y = magneticField.y
        self.z = magneticField.z
    }
    
    public init(activityData: CMMotionActivity) {
       
        self.activity = SensorActivity(activity: activityData)
    }
}

extension SensorActivity {
    public init(activity: CMMotionActivity) {
        self.cycling = activity.cycling
        self.running = activity.running
        self.walking = activity.walking
        self.stationary = activity.stationary
        self.in_car = activity.automotive
        self.unknown = activity.unknown
        switch activity.confidence {
        case .low:
            self.confidence = 0.0
        case .medium:
            self.confidence = 0.5
        case.high:
            self.confidence = 1.0
        @unknown default:
            self.confidence = 0.0
        }
    }
    
}
