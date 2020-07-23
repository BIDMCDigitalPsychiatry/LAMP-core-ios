//
//  RotationSensor.swift
//  com.lamp.ios.sensor.rotation
//
//  Created by Yuuki Nishiyama on 2018/10/30.
//

/**
 * var attitude:     CMAttitude     -> The attitude of the device.
 * var rotationRate: CMRotationRate -> The rotation rate of the device.
 */

import UIKit
import CoreMotion

extension Notification.Name{
    public static let actionLampRotation = Notification.Name(RotationSensor.ACTION_LAMP_ROTATION)
    public static let actionLampRotationStart = Notification.Name(RotationSensor.ACTION_LAMP_ROTATION)
    public static let actionLampRotationStop = Notification.Name(RotationSensor.ACTION_LAMP_ROTATION_STOP)
    public static let actionLampRotationSetLabel = Notification.Name(RotationSensor.ACTION_LAMP_ROTATION_SET_LABEL)
    public static let actionLampRotationSync = Notification.Name(RotationSensor.ACTION_LAMP_ROTATION_SYNC)
    
    public static let actionLampRotationSyncCompletion  = Notification.Name(RotationSensor.ACTION_LAMP_ROTATION_SYNC_COMPLETION)
    
}

public protocol RotationObserver{
    func onDataChanged(data:RotationData)
}

extension RotationSensor {
    public static var TAG = "LAMP::Rotation"
    
    public static var ACTION_LAMP_ROTATION = "ACTION_LAMP_ROTATION"
    
    public static var ACTION_LAMP_ROTATION_START = "com.lampframework.android.sensor.rotation.SENSOR_START"
    public static var ACTION_LAMP_ROTATION_STOP = "com.lampframework.android.sensor.rotation.SENSOR_STOP"
    
    public static var ACTION_LAMP_ROTATION_SET_LABEL = "com.lampframework.android.sensor.rotation.ACTION_LAMP_ROTATION_SET_LABEL"
    public static var EXTRA_LABEL = "label"
    
    public static var ACTION_LAMP_ROTATION_SYNC = "com.lampframework.android.sensor.rotation.SENSOR_SYNC"
    
    public static let ACTION_LAMP_ROTATION_SYNC_COMPLETION = "com.lampframework.ios.sensor.rotation.SENSOR_SYNC_COMPLETION"
    public static let EXTRA_STATUS = "status"
    public static let EXTRA_ERROR = "error"
}

/**
 * https://developer.apple.com/documentation/coremotion/getting_processed_device-motion_data
 * https://developer.apple.com/documentation/coremotion/getting_processed_device-motion_data/understanding_reference_frames_and_device_attitude
 */

public class RotationSensor: LampSensorCore {
    
    public var CONFIG = RotationSensor.Config()
    var motion = CMMotionManager()
    var LAST_DATA:CMDeviceMotion?
    var LAST_TS:Double   = Date().timeIntervalSince1970
    var LAST_SAVE:Double = Date().timeIntervalSince1970
    public var dataBuffer = Array<RotationData>()
    
    public class Config:SensorConfig{
        /**
         * For real-time observation of the sensor data collection.
         */
        public var sensorObserver: RotationObserver? = nil
        
        /**
         * Rotation interval in hertz per second: e.g.
         *
         * 0 - fastest
         * 1 - sample per second
         * 5 - sample per second
         * 20 - sample per second
         */
        public var frequency: Int = 5
        
        /**
         * Period to save data in minutes. (optional)
         */
        public var period: Double = 1.0
        
        /**
         * Rotation threshold (float).  Do not record consecutive points if
         * change in value is less than the set value.
         */
        public var threshold: Double = 0.0
        
        public override init(){
            super.init()
            //dbPath = "aware_rotation"
        }
        
        public override func set(config: Dictionary<String, Any>) {
            super.set(config: config)
            
            if let frequency = config["frequency"] as? Int {
                self.frequency = frequency
            }
            
            if let period = config["period"] as? Double {
                self.period = period
            }
            
            if let threshold = config["threshold"] as? Double {
                self.threshold = threshold
            }
            
        }
        
        public func apply(closure: (_ config:RotationSensor.Config) -> Void) -> Self {
            closure(self)
            return self
        }
    }
    
    public override convenience init(){
        self.init(RotationSensor.Config())
    }
    
    public init(_ config:RotationSensor.Config){
        super.init()
        self.CONFIG = config
        self.initializeDbEngine(config: config)
        if config.debug{ print(RotationSensor.TAG, "Rotation sensor is created.") }
    }
    
    public override func start() {
        if motion.isDeviceMotionAvailable{
            if !motion.isDeviceMotionActive {
                self.motion.deviceMotionUpdateInterval = 1.0/Double(CONFIG.frequency)
                self.motion.showsDeviceMovementDisplay = true // TODO: true of false ?
                // self.motion.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)
                self.motion.startDeviceMotionUpdates(to: .main) { (motionData, error) in
                    if let mData = motionData {
                        /**
                         * https://developer.apple.com/documentation/coremotion/getting_processed_device-motion_data/understanding_reference_frames_and_device_attitude
                         *
                         * The attitude property of the CMDeviceMotion object contains pitch, roll, and
                         * yaw values for the device that are relative to the reference frame. These values provide
                         * the device’s orientation in three-dimensional space. When all three values are 0, the
                         * device’s orientation matches the orientation of the reference frame. As the device rotates
                         * around each axis, the pitch, roll, and yaw values reflect the amount of rotation (in radians)
                         * around the given axis. Rotation values may be positive or negative and are in the range -∏ to ∏.
                         *
                         * TODO: check the data format between iOS and Android
                         */
                        let x = mData.attitude.roll
                        let y = mData.attitude.pitch
                        let z = mData.attitude.yaw
                        let accuracy = mData.magneticField.accuracy
                        if let lastData = self.LAST_DATA {
                            if self.CONFIG.threshold > 0 &&
                                abs(x - lastData.attitude.roll ) < self.CONFIG.threshold &&
                                abs(y - lastData.attitude.pitch) < self.CONFIG.threshold &&
                                abs(z - lastData.attitude.yaw)   < self.CONFIG.threshold {
                                return
                            }
                        }
                        
                        self.LAST_DATA = mData
                        let currentTime:Double = Date().timeIntervalSince1970
                        self.LAST_TS = currentTime
                        
                        let data = RotationData()
                        data.x = x
                        data.y = y
                        data.z = z
                        data.eventTimestamp = Int64(mData.timestamp * 1000)
                        switch accuracy {
                        case .uncalibrated:
                            data.accuracy = 0 // SENSOR_STATUS_UNRELIABLE
                            break
                        case .low:
                            data.accuracy = 1 // SENSOR_STATUS_ACCURACY_LOW
                            break
                        case .medium:
                            data.accuracy = 2 // SENSOR_STATUS_ACCURACY_MEDIUM
                            break
                        case .high:
                            data.accuracy = 3 // SENSOR_STATUS_ACCURACY_HIGH
                            break
                        @unknown default:
                            data.accuracy = 2
                        }
                        data.label = self.CONFIG.label
                        
                        if let observer = self.CONFIG.sensorObserver{
                            observer.onDataChanged(data: data)
                        }
                        
                        self.dataBuffer.append(data)
                        
                        if currentTime < self.LAST_SAVE + (self.CONFIG.period * 60) {
                            return
                        }
                        
                        let dataArray = Array(self.dataBuffer)
                        if let engine = self.dbEngine{
                            let queue = DispatchQueue(label:"com.lampframework.ios.sensor.rotation.save.queue")
                            queue.async {
                                engine.save(dataArray){ error in
                                    if error == nil {
                                        DispatchQueue.main.async {
                                            self.notificationCenter.post(name: .actionLampRotation, object: self)
                                        }
                                    }else{
                                        if self.CONFIG.debug{ print(error!) }
                                    }
                                }
                            }
                        }
                        if self.dataBuffer.count > 1 {
                            self.dataBuffer.removeFirst()
                        }
                        self.LAST_SAVE = currentTime
                        
                    }
                }
                self.notificationCenter.post(name: .actionLampRotationStart, object: self)
            }
        }
    }
    
    public override func stop() {
        if motion.isDeviceMotionActive{
            if motion.isDeviceMotionActive{
                self.motion.stopDeviceMotionUpdates()
                self.notificationCenter.post(name: .actionLampRotationStop, object: self)
            }
        }
    }
    
    public override func sync(force: Bool = false) {
        self.notificationCenter.post(name: .actionLampRotationSync, object: self)
    }
    
    public override func set(label:String) {
        self.CONFIG.label = label
        self.notificationCenter.post(name: .actionLampRotationSetLabel,
                                     object: self,
                                     userInfo: [RotationSensor.EXTRA_LABEL:label])
    }
}

extension RotationSensor {
    
    /// Returns the last stored sensor data in the dataBuffer array.
    public func latestData() -> RotationData? {
        return dataBuffer.last
    }
}
