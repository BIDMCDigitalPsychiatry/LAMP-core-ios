// mindLAMPWatch Extension

import Foundation
import CoreMotion
import WatchKit
import Sensors

extension Date {
    var millisecondsSince1970: Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}

class LMWatchSensorManager {
    
    private let sensorManager = SensorManager()
    var sensor_motionManager: MotionManager?
    
    // SensorData storage variables.
    var accelerometerDataBufffer = [AccelerometerData]()
    var gyroscopeDataBufffer = [GyroscopeData]()
    var magnetometerDataBufffer = [MagnetometerData]()
    var motionDataBuffer = [MotionData]()
    
    //check if the sensors are started or not
    private var isStarted = false
    
    let wristLocationIsLeft = WKInterfaceDevice.current().wristLocation == .left
    
    
    var completionHandler: ((WKBackgroundFetchResult) -> Void)?
    
    static let shared = LMWatchSensorManager()
    private init() {
        //        queue.maxConcurrentOperationCount = 1
        //        queue.name = "LMWatchSensorManagerQueue"
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).sensorDataPosted(_:)),
            name: .userLogOut, object: nil
        )
    }
    
    func startSensors() {
        sensor_motionManager = MotionManager.init(MotionManager.Config().apply(closure: { [weak self] (config) in
            config.accelerometerObserver = self
            config.gyroObserver = self
            config.magnetoObserver = self
            config.motionObserver = self
            config.sensorTimerDelegate = self
        }))
        
        sensorManager.addSensors([sensor_motionManager!])
        
        isStarted = true
        sensorManager.startAllSensors()
    }
    
    func stop() {
        sensorManager.stopAllSensors()
    }
    
    func getSensorDataRequest() -> SensorData.Request {
        
        return SensorData.Request(sensorEvents: getSensorDataArrray())
    }
    
    func checkIsRunning() {
        if self.isStarted == false {
            startSensors()
        }
        BackgroundServices.shared.performTasks()
    }
}

//MARK: - Private functions
private extension LMWatchSensorManager {
    
    func getSensorDataArrray() -> [SensorDataInfo] {
        var arraySensorData = [SensorDataInfo]()
        
        arraySensorData.append(contentsOf: fetchAccelerometerData())
        arraySensorData.append(contentsOf: fetchGyroscopeData())
        arraySensorData.append(contentsOf: fetchMagnetometerData())
        arraySensorData.append(contentsOf: fetchAccelerometerMotionData())

        return arraySensorData
    }
    
    @objc
    func sensorDataPosted(_ notification: Notification) {
        self.completionHandler?(.newData)
        self.completionHandler = nil
    }
    
    func fetchMagnetometerData() -> [SensorDataInfo] {
        
        let dataArray = motionDataBuffer
        motionDataBuffer.removeAll(keepingCapacity: true)
        
        let sensorArray = dataArray.map {
            SensorDataInfo(sensor: SensorType.lamp_magnetometer.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(magneticField: $0.magneticField))
        }
        return sensorArray
    }
    
    func fetchGyroscopeData() -> [SensorDataInfo] {
        
        let dataArray = gyroscopeDataBufffer
        gyroscopeDataBufffer.removeAll(keepingCapacity: true)
        
        let sensorArray = dataArray.map {
            SensorDataInfo(sensor: SensorType.lamp_gyroscope.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(rotationRate: $0.rotationRate))
        }
        return sensorArray
    }
    
    func fetchAccelerometerData() -> [SensorDataInfo] {
        
        let dataArray = accelerometerDataBufffer
        accelerometerDataBufffer.removeAll(keepingCapacity: true)
        
        let sensorArray = dataArray.map {
            SensorDataInfo(sensor: SensorType.lamp_accelerometer.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(accelerationRate: $0.acceleration))
        }
        return sensorArray
    }

    func fetchAccelerometerMotionData() -> [SensorDataInfo] {
        
        let dataArray = motionDataBuffer
        motionDataBuffer.removeAll(keepingCapacity: true)
        
        let sensorArray = dataArray.map {
            SensorDataInfo(sensor: SensorType.lamp_accelerometer_motion.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(motionData: $0))
        }
        return sensorArray
    }
}

extension LMWatchSensorManager: WatchOSDelegate {
    
    func messageReceived(tuple: MessageReceived) {
    }
//    @objc private func sendSensorEventsNow() {
//        stop()
//        SensorEvents().postSensorData()
//    }
//
//    func sendSensorEvents(_ completionHandler: ((WKBackgroundFetchResult) -> Void)? = nil) {
//        startSensors()
//        self.completionHandler = completionHandler
//        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.sendSensorEventsNow), userInfo: nil, repeats: false)
//    }
    
    func applicationContextReceived(tuple: ApplicationContextReceived) {
        
        DispatchQueue.main.async() {
            if let loginDict = tuple.applicationContext[IOSCommands.login] as? [String: Any] {
                let loginInfo = LoginInfo(loginDict)
                Endpoint.setSessionKey(loginInfo.sessionToken)
                User.shared.login(userID: loginInfo.userId, serverAddress: loginInfo.serverAddress)
                Utils.postNotificationOnMainQueueAsync(name: .userLogined)
                //WKInterfaceDevice.current().play(.notification)
                LMWatchSensorManager.shared.checkIsRunning()
            } else if let _ = tuple.applicationContext[IOSCommands.sendWatchSensorEvents] as? Bool {
                //LMWatchSensorManager.shared.sendSensorEvents()
                LMWatchSensorManager.shared.checkIsRunning()
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
