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

extension SensorData.Request: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(sensorEvents)
    }
    
//    public init(from decoder: Decoder) throws {
//        do {
//            let container = try decoder.singleValueContainer()
//            sensorEvents = try container.decode([SensorEvent<SensorDataModel>].self)
//        } catch {
//            assertionFailure("ERROR: \(error)")
//            sensorEvents = []
//        }
//    }
}

public enum SensorKitData {

    public struct Request {
        public var sensorEvents: [SensorKitEvent]
        public init(sensorEvents: [SensorKitEvent]) {
            self.sensorEvents = sensorEvents
        }
        
        func toData() -> Data? {
            guard sensorEvents.count > 0 else { return nil }
            do {
                let array = sensorEvents.map({$0.toJSON()})
                let jsonData = try JSONSerialization.data(withJSONObject: array)
                return jsonData
            } catch let error {
                print("error jp = \(error.localizedDescription)")
                return nil
            }
        }
    }
}


public struct UserAgent {
    var type: String
    var os_version: String
    var app_version: String
    var model: String
    public init(type: String, os_version: String, app_version: String, model: String) {
        self.type = type
        self.os_version = os_version
        self.app_version = app_version
        self.model = model
    }
}

extension UserAgent {
    public func toString() -> String {
        let appSource = Environment.appSource
        return "\(appSource) \(app_version); iOS \(os_version); \(type) \(model)"
    }
}


extension Encodable {
  var dictionary: [String: Any]? {
    guard let data = try? JSONEncoder().encode(self) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
  }
}


public struct PayLoadInfo {
    var type: String
    // removed this, as it has the useragent. var device_type: String// = "iOS" //"Android" or "Web"
    var user_agent: UserAgent?
    var payload: [String: Any]?
    var diagnostics: [String: Any]?
    public init(action: SensorType.AnalyticAction, userInfo: [AnyHashable: Any], userAgent: UserAgent?) {
        self.type = action.rawValue
        self.user_agent = userAgent
        // self.device_type = DeviceType.displayName
        if action == SensorType.AnalyticAction.diagnostic {
            diagnostics = Diagnostics().dictionary
        } else {
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
    }
    
    public func toJSON() -> [String: Any] {
        let content = type == SensorType.AnalyticAction.diagnostic.rawValue ? diagnostics : payload
        return ["type": type,
                "payload": content ?? NSNull(),
                // "device_type": device_type,
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
    
    var type: String? //SensorType.AnalyticAction.login.rawValue
    var device_type: String// = "iOS" //"Android" or "Web"
    var user_agent: String?
    var device_token: String?
    
    public init(deviceToken: String?, userAgent: UserAgent?, action: String?) {
        self.type = action
        self.device_token = deviceToken
        self.user_agent = userAgent?.toString()
        self.device_type = DeviceType.displayName
    }
}

public struct SensorDataModel: Codable {
    
    public struct Pressure: Codable {
        var value: Double
        var units: String?
        var source: String?
        var timestamp: UInt64?
    }
    
    public init(){}
    public var systolic: Pressure?
    public var diastolic: Pressure?
    //healthkit, steps allow (null)
    public var source: Tristate?
    public var device_model: Tristate?
    
    //Location
    public var latitude: Double?
    public var longitude: Double?
    public var altitude: Double?
    public var accuracy: Double?
    
    //Triaxial Values for: Accelerometer, Magnetometer, Gyroscope
    public var x: Double?
    public var y: Double?
    public var z: Double?
    //MotionData
    public var motion: Motion?
    public var rotation: Rotational?
    public var gravity: Gravitational?
    public var magnetic: Magnetic?
    public var attitude: Attitude?
    
    //PedometerData
    public var value: Double?
    
    //lamp.nearby_device
    public var type: String? //Calls, lamp.steps
    public var address: String?
    public var name: String?
    public var strength: Int?
    
    //Calls
    public var duration: Double?//used for sleep also
    
    public var activity: SensorActivity?
    
    //Health
    public var unit: String?
    public var representation: String?
    public var workout_type: String?
    public var workout_duration: Double?
    
    //glucose
    public var meal_time: String?
    
    //screen data
    public var battery_level: Float?
    
    public var startDate: Double?
    public var endDate: Double?
    //analytics
    // renamed to type var action: String?
    var device_type: String?// = "iOS" //"Android" or "Web"
    var user_agent: String?
    var message: String?
    
    enum CodingKeys: String, CodingKey {
        
        case source
        case device_model
        //Location
        case latitude
        case longitude
        case altitude
        case accuracy
        
        case x
        case y
        case z
        case motion
        case rotation
        case gravity
        case magnetic
        case attitude
        
        case value
        
        case type
        case address
        case name
        case strength
        
        case duration
        
        case activity
        //Health
        case unit
        case representation
        case workout_type
        case workout_duration
        //pressure
        case systolic
        case diastolic
        //screen data
        case battery_level
        //glucose
        case meal_time
        //lamp.analytics
        // case action //renamed to type
        case device_type
        case user_agent
        case message
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
    var x: Double?
    var y: Double?
    var z: Double?
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
    // for lowpowermode lamp.analytics
    public init(action: String?, userAgent: UserAgent?, value: Bool) {
        self.type = action
        self.user_agent = userAgent?.toString()
        self.device_type = DeviceType.displayName
        self.value = value ? 1 : 0
    }

    //for log lamp.analytics
    public init(action: String?, userAgent: UserAgent?, errorMsg: String?) {
        self.type = action
        self.user_agent = userAgent?.toString()
        self.device_type = DeviceType.displayName
        self.message = errorMsg
    }

    public init(screenData: ScreenStateData) {
        self.value = Double(screenData.screenState.rawValue)
        self.representation = screenData.screenState.stringValue
        self.battery_level = screenData.batteryLevel
    }
    
    public init(callsData: CallsData) {
        self.type = callsData.type
        self.duration = callsData.duration
    }
    
    public init(locationData: LocationsData) {
        self.latitude = locationData.latitude
        self.longitude = locationData.longitude
        self.altitude = locationData.altitude
        self.accuracy = locationData.accuracy
    }
    
    public init(motionData: MotionData) {
        
        //User Acceleration
        let motion = Motion(x: motionData.acceleration.x, y: motionData.acceleration.y, z: motionData.acceleration.z)
        self.motion = motion
        
        //Gyro
        let rotation = Rotational(x: motionData.rotationRate.x, y: motionData.rotationRate.y, z: motionData.rotationRate.z)
        self.rotation = rotation
        
        //Gravity
        let gravity = Gravitational(x: motionData.gravity.x, y: motionData.gravity.y, z: motionData.gravity.z)
        self.gravity = gravity
        
        //MageticField
        let magnetic = Magnetic(x: motionData.magneticField.x, y: motionData.magneticField.y, z: motionData.magneticField.z)
        self.magnetic = magnetic
        
        //Attitude
        let attitude = Attitude(x: motionData.deviceAttitude.roll, y: motionData.deviceAttitude.pitch, z: motionData.deviceAttitude.yaw)
        self.attitude = attitude
    }
    
    public init(pedometerData: PedometerData) {
        
        self.type = pedometerData.type
        self.value = pedometerData.value
        self.unit = pedometerData.unit
        self.source = Tristate(pedometerData.source)
    }
}

extension SensorDataModel {

    public init(accelerationRate: CMAcceleration) {
        self.x = accelerationRate.x
        self.y = accelerationRate.y
        self.z = accelerationRate.z
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
