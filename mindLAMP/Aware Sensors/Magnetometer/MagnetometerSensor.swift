//
//  MagnetometerSensor.swift
//  com.aware.ios.sensor.magnetometer
//
//  Created by Yuuki Nishiyama on 2018/10/30.
//

import UIKit
import CoreMotion

extension Notification.Name{
    public static let actionAwareMagnetometer      = Notification.Name(MagnetometerSensor.ACTION_AWARE_MAGNETOMETER)
    public static let actionAwareMagnetometerStart = Notification.Name(MagnetometerSensor.ACTION_AWARE_MAGNETOMETER_START)
    public static let actionAwareMagnetometerStop  = Notification.Name(MagnetometerSensor.ACTION_AWARE_MAGNETOMETER_STOP)
    public static let actionAwareMagnetometerSetLabel = Notification.Name(MagnetometerSensor.ACTION_AWARE_MAGNETOMETER_SET_LABEL)
    public static let actionAwareMagnetometerSync  = Notification.Name(MagnetometerSensor.ACTION_AWARE_MAGNETOMETER_SYNC)
    
    public static let actionAwareMagnetometerSyncCompletion  = Notification.Name(MagnetometerSensor.ACTION_AWARE_MAGNETOMETER_SYNC_COMPLETION)
    
}

public protocol MagnetometerObserver{
    func onDataChanged(data:MagnetometerData)
}

extension MagnetometerSensor{
    public static var TAG = "AWARE::Magnetometer"
    
    public static var ACTION_AWARE_MAGNETOMETER = "ACTION_AWARE_MAGNETOMETER"
    
    public static var ACTION_AWARE_MAGNETOMETER_START = "com.awareframework.android.sensor.magnetometer.SENSOR_START"
    public static var ACTION_AWARE_MAGNETOMETER_STOP = "com.awareframework.android.sensor.magnetometer.SENSOR_STOP"
    
    public static var ACTION_AWARE_MAGNETOMETER_SET_LABEL = "com.awareframework.android.sensor.magnetometer.ACTION_AWARE_MAGNETOMETER_SET_LABEL"
    public static var EXTRA_LABEL = "label"
    
    public static var ACTION_AWARE_MAGNETOMETER_SYNC = "com.awareframework.android.sensor.magnetometer.SENSOR_SYNC"
    
    public static let ACTION_AWARE_MAGNETOMETER_SYNC_COMPLETION = "com.awareframework.ios.sensor.magnetometer.SENSOR_SYNC_COMPLETION"
    public static let EXTRA_STATUS = "status"
    public static let EXTRA_ERROR = "error"
}

public class MagnetometerSensor: AwareSensor {
    public var CONFIG = Config()
    var motion = CMMotionManager()
    var LAST_DATA:CMMagneticField?
    var LAST_TS:Double   = Date().timeIntervalSince1970
    var LAST_SAVE:Double = Date().timeIntervalSince1970
    public var dataBuffer = Array<MagnetometerData>()
    
    public class Config:SensorConfig{
        /**
         * For real-time observation of the sensor data collection.
         */
        public var sensorObserver: MagnetometerObserver? = nil
        
        /**
         * Magnetometer frequency in hertz per second: e.g.
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
        public var period: Double = 1
        
        /**
         * Magnetometer threshold (float).  Do not record consecutive points if
         * change in value is less than the set value.
         */
        public var threshold: Double = 0.0
    
        public override init() {
            super.init()
            dbPath = "aware_magnetometer"
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
        
        public func apply(closure:(_ config: MagnetometerSensor.Config) -> Void) -> Self {
            closure(self)
            return self
        }
    }
    
    public override convenience init(){
        self.init(MagnetometerSensor.Config())
    }
    
    public init(_ config:MagnetometerSensor.Config){
        super.init()
        self.CONFIG = config
        self.initializeDbEngine(config: config)
        if config.debug{ print(MagnetometerSensor.TAG, "Magnetometer sensor is created. ") }
    }
    
    public override func start() {
        if self.motion.isMagnetometerAvailable && !self.motion.isMagnetometerActive{
            self.motion.magnetometerUpdateInterval = 1.0/Double(CONFIG.frequency)
            self.motion.startMagnetometerUpdates(to: .main) { (magnetometerData, error) in
                if let magData = magnetometerData {
                    let x = magData.magneticField.x
                    let y = magData.magneticField.y
                    let z = magData.magneticField.z
                    if let lastData = self.LAST_DATA {
                        if self.CONFIG.threshold > 0 &&
                            abs(x - lastData.x) < self.CONFIG.threshold &&
                            abs(y - lastData.y) < self.CONFIG.threshold &&
                            abs(z - lastData.z) < self.CONFIG.threshold {
                            return
                        }
                    }
                    self.LAST_DATA = magData.magneticField
                    
                    let currentTime:Double = Date().timeIntervalSince1970
                    self.LAST_TS = currentTime
                    
                    let data = MagnetometerData()
                    data.timestamp = Int64(currentTime*1000)
                    data.x = magData.magneticField.x
                    data.y = magData.magneticField.y
                    data.z = magData.magneticField.z
                    data.eventTimestamp = Int64(magData.timestamp*1000)
                    data.label = self.CONFIG.label
                    
                    if let observer = self.CONFIG.sensorObserver {
                        observer.onDataChanged(data: data)
                    }
                    
                    self.dataBuffer.append(data)
                    
                    if currentTime < self.LAST_SAVE + (self.CONFIG.period * 60) {
                        return
                    }
                    
                    let dataArray = Array(self.dataBuffer)
                    
                    if let engine = self.dbEngine{
                        let queue = DispatchQueue(label:"com.awareframework.ios.sensor.magnetometer.save.queue")
                        queue.sync {
                            engine.save(dataArray){ error in
                                if error == nil {
                                    DispatchQueue.main.async {
                                        self.notificationCenter.post(name: .actionAwareMagnetometer, object: self)
                                    }
                                }else{
                                    if self.CONFIG.debug {
                                        print(error!)
                                    }
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
            self.notificationCenter.post(name: .actionAwareMagnetometerStart, object: self)
        }
    }
    
    public override func stop() {
        if motion.isMagnetometerAvailable && motion.isMagnetometerActive {
            motion.stopMagnetometerUpdates()
            self.notificationCenter.post(name: .actionAwareMagnetometerStop, object: self)
        }
    }
    
    public override func sync(force: Bool = false) {
        self.notificationCenter.post(name: .actionAwareMagnetometerSync, object: self)
    }
    
    public override func set(label:String){
        self.CONFIG.label = label
        self.notificationCenter.post(name: .actionAwareMagnetometerSetLabel,
                                     object: self,
                                     userInfo: [MagnetometerSensor.EXTRA_LABEL:label])
    }
}

extension MagnetometerSensor {
    
    /// Returns the last stored sensor data in the dataBuffer array.
    public func latestData() -> MagnetometerData? {
        return dataBuffer.last
    }
}
