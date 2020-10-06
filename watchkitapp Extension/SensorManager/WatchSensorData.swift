// watchkitapp Extension

import Foundation
import Sensors

class WatchSensorData {
    
    static let shared = WatchSensorData()
    // MARK: - VARIABLES
    private let motionManager = SensorManager()
   
    // SensorData storage variables.
    var accelerometerDataBufffer = [AccelerometerData]()
    var gyroscopeDataBufffer = [GyroscopeData]()
    var magnetometerDataBufffer = [MagnetometerData]()
    var motionDataBuffer = [MotionData]()
    
    private init () {
        let sensor_accelerometer = AccelerometerSensor.init(AccelerometerSensor.Config().apply{ config in
            config.sensorObserver = self
        })
        let sensor_gyro = GyroscopeSensor.init(GyroscopeSensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
        
        let sensor_magneto = MagnetometerSensor.init(MagnetometerSensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
        let sensor_motion = MotionSensor.init(MotionSensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
        
        motionManager.addSensors([sensor_accelerometer, sensor_gyro, sensor_magneto, sensor_motion])
    }
    
    func start() {
        motionManager.startAllSensors()
    }
    
    func stop() {
        motionManager.stopAllSensors()
    }
    
    func fetchMagnetometerData() -> [SensorDataInfo]? {
        
        let dataArray = motionDataBuffer
        motionDataBuffer.removeAll(keepingCapacity: true)
        
        let sensorArray = dataArray.map {
            SensorDataInfo(sensor: SensorType.lamp_magnetometer.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(magneticField: $0.magneticField))
        }
        return sensorArray
    }
    
    func fetchGyroscopeData() -> [SensorDataInfo]? {
        
        let dataArray = gyroscopeDataBufffer
        gyroscopeDataBufffer.removeAll(keepingCapacity: true)
        
        let sensorArray = dataArray.map {
            SensorDataInfo(sensor: SensorType.lamp_gyroscope.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(rotationRate: $0.rotationRate))
        }
        return sensorArray
    }
    
    func fetchAccelerometerData() -> [SensorDataInfo]? {
        
        let dataArray = accelerometerDataBufffer
        accelerometerDataBufffer.removeAll(keepingCapacity: true)
        
        let sensorArray = dataArray.map {
            SensorDataInfo(sensor: SensorType.lamp_accelerometer.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(accelerationRate: $0.acceleration))
        }
        return sensorArray
    }

    func fetchAccelerometerMotionData() -> [SensorDataInfo]? {
        
        let dataArray = motionDataBuffer
        motionDataBuffer.removeAll(keepingCapacity: true)
        
        let sensorArray = dataArray.map {
            SensorDataInfo(sensor: SensorType.lamp_accelerometer_motion.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(motionData: $0))
        }
        return sensorArray
    }
}

// MARK: - GyroscopeObserver
extension WatchSensorData: GyroscopeObserver {
    
    public func onDataChanged(data: GyroscopeData) {
        gyroscopeDataBufffer.append(data)
    }
}


// MARK: - AccelerometerObserver
extension WatchSensorData: AccelerometerObserver {
    
    public func onDataChanged(data: AccelerometerData) {
        accelerometerDataBufffer.append(data)
    }
}

// MARK: - GravityObserver
extension WatchSensorData: MotionObserver {
    
    public func onDataChanged(data: MotionData) {
        motionDataBuffer.append(data)
    }
}

// MARK:- MagnetometerObserver
extension WatchSensorData: MagnetometerObserver {

    func onDataChanged(data: MagnetometerData) {
        magnetometerDataBufffer.append(data)
    }
}
