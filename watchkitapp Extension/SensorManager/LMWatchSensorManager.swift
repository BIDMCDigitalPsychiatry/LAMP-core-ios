// mindLAMPWatch Extension

import Foundation
import CoreMotion
import WatchKit

//let kAccelerometerDataIdentifier: String = "AccelerometerData"
//let kGravityDataIdentifier: String = "GravityData"
//let kRotationDataIdentifier: String = "RotationData"
//let kAttitudeDataIdentifier: String = "AttitudeData"

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}

class LMWatchSensorManager {
    
    let motionManager = CMMotionManager()
    let queue = OperationQueue()
    let wristLocationIsLeft = WKInterfaceDevice.current().wristLocation == .left
    let sampleInterval = 1.0 / 50
    let rateAlongGravityBuffer = RunningBuffer(size: 50)
    
    var gravityStr = ""
    var rotationRateStr = ""
    var userAccelStr = ""
    var attitudeStr = ""
    
    var recentDetection = false
    
    var garvityDataBuffer:Array<GravityData>  = Array<GravityData>()
    var accelerometerDataBuffer:Array<AccelerometerData>  = Array<AccelerometerData>()
    var rotationDataBuffer:Array<RotationData>  = Array<RotationData>()
    var attitudeDataBuffer:Array<AttitudeData>  = Array<AttitudeData>()
    
    var completionHandler: ((WKBackgroundFetchResult) -> Void)?
    
    static let shared = LMWatchSensorManager()
    private init() {
        queue.maxConcurrentOperationCount = 1
        queue.name = "LMWatchSensorManagerQueue"
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).sensorDataPosted(_:)),
            name: .userLogOut, object: nil
        )
    }
    
    private func startUpdates() {
        if !motionManager.isDeviceMotionAvailable {
            print("Device Motion is not available.")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = sampleInterval
        motionManager.startDeviceMotionUpdates(to: queue) { (deviceMotion: CMDeviceMotion?, error: Error?) in
            if error != nil {
                print("Encountered error: \(error!)")
            }
            
            if deviceMotion != nil {
                self.processDeviceMotion(deviceMotion!)
            }
        }
    }

    func processDeviceMotion(_ deviceMotion: CMDeviceMotion) {
        
        let currentTime:Double = Date().timeIntervalSince1970
        
        let userAccelData = AccelerometerData()
        userAccelData.timestamp = Int64(currentTime*1000)
        userAccelData.x = deviceMotion.userAcceleration.x
        userAccelData.y = deviceMotion.userAcceleration.y
        userAccelData.z = deviceMotion.userAcceleration.z
        userAccelData.eventTimestamp = Int64(currentTime*1000)
        accelerometerDataBuffer.append(userAccelData)
        
        let gravityData = GravityData()
        gravityData.timestamp = Int64(currentTime*1000)
        gravityData.x = deviceMotion.gravity.x
        gravityData.y = deviceMotion.gravity.y
        gravityData.z = deviceMotion.gravity.z
        gravityData.eventTimestamp = Int64(currentTime*1000)
        garvityDataBuffer.append(gravityData)
        
        let rotationData = RotationData()
        rotationData.timestamp = Int64(currentTime*1000)
        rotationData.x = deviceMotion.rotationRate.x
        rotationData.y = deviceMotion.rotationRate.y
        rotationData.z = deviceMotion.rotationRate.z
        rotationData.eventTimestamp = Int64(currentTime*1000)
        rotationDataBuffer.append(rotationData)
        
        let attitudeData = AttitudeData()
        attitudeData.timestamp = Int64(currentTime*1000)
        attitudeData.roll = deviceMotion.attitude.roll
        attitudeData.pitch = deviceMotion.attitude.pitch
        attitudeData.yaw = deviceMotion.attitude.yaw
        attitudeData.eventTimestamp = Int64(currentTime*1000)
        attitudeDataBuffer.append(attitudeData)
    }
    
    private func getSensorDataArrray() -> [SensorDataInfo] {
        var arraySensorData = [SensorDataInfo]()

        if let data = fetchAccelerometerData() {
            arraySensorData.append(data)
        }
        if let data = fetchAccelerometerMotionData() {
            arraySensorData.append(data)
        }
        return arraySensorData
    }

    func getLatestDataRequest() -> SensorData.Request {
        
        return SensorData.Request(sensorEvents: getSensorDataArrray())
    }
}

//MARK: - Private functions
private extension LMWatchSensorManager {
    
    func fetchAccelerometerData() -> SensorDataInfo? {
        guard let data = accelerometerDataBuffer.last else {
            return nil
        }
        var model = SensorDataModel()
        model.x = data.x
        model.y = data.y
        model.z = data.z
        
        return SensorDataInfo(sensor: SensorType.lamp_watch_accelerometer.jsonKey, timestamp: Double(data.timestamp), data: model)
    }
        
    func fetchAccelerometerMotionData() -> SensorDataInfo? {
        
        let timeStamp = Date().timeInMilliSeconds
        var model = SensorDataModel()
        
        if let data = accelerometerDataBuffer.last {
            var motion = Motion()
            motion.x = data.x
            motion.y = data.y
            motion.z = data.z
            
            model.motion = motion
        }
        
        if let data = garvityDataBuffer.last {
            var gravity = Gravitational()
            gravity.x = data.x
            gravity.y = data.y
            gravity.z = data.z
            
            model.gravity = gravity
        }
        
        if let data = rotationDataBuffer.last {
            var rotation = Rotational()
            rotation.x = data.x
            rotation.y = data.y
            rotation.z = data.z
            
            model.rotation = rotation
        }
        
        if let data = attitudeDataBuffer.last {
            var attitude = Attitude()
            attitude.roll = data.roll
            attitude.pitch = data.pitch
            attitude.yaw = data.yaw
            
            model.attitude = attitude
        }
        
        return SensorDataInfo(sensor: SensorType.lamp_watch_accelerometer_motion.jsonKey, timestamp: timeStamp, data: model)
    }
    
    @objc
    func sensorDataPosted(_ notification: Notification) {
        self.completionHandler?(.newData)
        self.completionHandler = nil
    }
}
extension LMWatchSensorManager: WatchOSDelegate {
    
    func messageReceived(tuple: MessageReceived) {
    }
    
    @objc private func sendSensorEventsNow() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.stopDeviceMotionUpdates()
        }
        SensorEvents().postSensorData()
    }
    
    func sendSensorEvents(_ completionHandler: ((WKBackgroundFetchResult) -> Void)? = nil) {
        LMWatchSensorManager.shared.startUpdates()
        self.completionHandler = completionHandler
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.sendSensorEventsNow), userInfo: nil, repeats: false)
    }
    
    func applicationContextReceived(tuple: ApplicationContextReceived) {
        
        DispatchQueue.main.async() {
            if let loginDict = tuple.applicationContext[IOSCommands.login] as? [String: Any] {
                let loginInfo = LoginInfo(loginDict)
                Endpoint.setSessionKey(loginInfo.sessionToken)
                User.shared.login(userID: loginInfo.userId, serverAddress: nil)
                Utils.postNotificationOnMainQueueAsync(name: .userLogined)
                WKInterfaceDevice.current().play(.notification)
            } else if let _ = tuple.applicationContext[IOSCommands.sendWatchSensorEvents] as? Bool {
                LMWatchSensorManager.shared.sendSensorEvents()
            } else if let _ = tuple.applicationContext[IOSCommands.logout] as? Bool {
                let isLoginPreviously = User.shared.isLogin()
                User.shared.logout()
                Utils.postNotificationOnMainQueueAsync(name: .userLogOut)
                if isLoginPreviously {
                    WKExtension.shared().unregisterForRemoteNotifications()
                }
            }
        }
    }
}
