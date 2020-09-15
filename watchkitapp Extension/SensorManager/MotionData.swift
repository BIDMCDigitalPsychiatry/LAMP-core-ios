// watchkitapp Extension

import Foundation
//import Sensors

class MotionData {
    
    static let shared = MotionData()
    // MARK: - VARIABLES
    private let motionManager = SensorManager()
    
    var garvityDataBuffer: GravityData?
    var accelerometerDataBuffer: AccelerometerData?
    var rotationDataBuffer: RotationData?
    var gyroDataBuffer: GyroscopeData?
    var magnetoDataBuffer: MagnetometerData?
    
    private init () {
        let sensor_accelerometer = AccelerometerSensor.init(AccelerometerSensor.Config().apply{ config in
            config.sensorObserver = self
            config.frequency = 1
        })
       
        let sensor_gravity = GravitySensor.init(GravitySensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
        let sensor_gyro = GyroscopeSensor.init(GyroscopeSensor.Config().apply(closure: { config in
            config.sensorObserver = self
            config.frequency = 1
        }))
        let sensor_magneto = MagnetometerSensor.init(MagnetometerSensor.Config().apply(closure: { config in
            config.sensorObserver = self
            config.frequency = 1
        }))
        let sensor_rotation = RotationSensor.init(RotationSensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
        
        motionManager.addSensors([sensor_accelerometer, sensor_gravity, sensor_gyro, sensor_magneto, sensor_rotation])
    }
    
    func start() {
        motionManager.startAllSensors()
    }
    
    func stop() {
        motionManager.stopAllSensors()
    }
    
    func fetchGyroscopeData() -> SensorDataInfo? {
        guard let data = gyroDataBuffer else {
            return nil
        }
        var model = SensorDataModel()
        model.x = data.x
        model.y = data.y
        model.z = data.z
        
        return SensorDataInfo(sensor: SensorType.lamp_gyroscope.lampIdentifier, timestamp: Double(data.timestamp), data: model)
    }
    
    func fetchAccelerometerData() -> SensorDataInfo? {
        guard let data = accelerometerDataBuffer else {
            return nil
        }
        var model = SensorDataModel()
        model.x = data.x
        model.y = data.y
        model.z = data.z
        
        return SensorDataInfo(sensor: SensorType.lamp_accelerometer.lampIdentifier, timestamp: Double(data.timestamp), data: model)
    }
        
    func fetchAccelerometerMotionData() -> SensorDataInfo? {
        
        let timeStamp = Date().timeInMilliSeconds
        var model = SensorDataModel()
        
        if let data = accelerometerDataBuffer {
            var motion = Motion()
            motion.x = data.x
            motion.y = data.y
            motion.z = data.z
            model.motion = motion
        }
        
        if let data = garvityDataBuffer {
            var gravity = Gravitational()
            gravity.x = data.x
            gravity.y = data.y
            gravity.z = data.z
            model.gravity = gravity
        }
        
        if let data = rotationDataBuffer {
            var rotation = Rotational()
            rotation.roll = data.roll
            rotation.pitch = data.pitch
            rotation.yaw = data.yaw
            model.rotation = rotation
        }
        
        if let data = magnetoDataBuffer {
            var magnetic = Magnetic()
            magnetic.x = data.x
            magnetic.y = data.y
            magnetic.z = data.z
            model.magnetic = magnetic
        }
        
        return SensorDataInfo(sensor: SensorType.lamp_accelerometer_motion.lampIdentifier, timestamp: timeStamp, data: model)
    }
}

// MARK: - GyroscopeObserver
extension MotionData: GyroscopeObserver {
    
    public func onDataChanged(data: GyroscopeData) {
        gyroDataBuffer = data
    }
}


// MARK: - AccelerometerObserver
extension MotionData: AccelerometerObserver {
    
    public func onDataChanged(data: AccelerometerData) {
        accelerometerDataBuffer = data
    }
}

// MARK: - GravityObserver
extension MotionData: GravityObserver {
    
    public func onDataChanged(data: GravityData) {
        garvityDataBuffer = data
    }
}

// MARK:- MagnetometerObserver
extension MotionData: MagnetometerObserver {
    
    func onDataChanged(data: MagnetometerData) {
        magnetoDataBuffer = data
    }
}

// MARK: - RotationObserver
extension MotionData: RotationObserver {
    
    func onDataChanged(data: RotationData) {
        rotationDataBuffer = data
    }
}
