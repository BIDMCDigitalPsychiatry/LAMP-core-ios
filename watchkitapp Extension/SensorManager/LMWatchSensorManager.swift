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
    var sensor_location: LocationsSensor?
    
    // SensorData storage variables.
    var accelerometerDataBufffer = [AccelerometerData]()
    var gyroscopeDataBufffer = [GyroscopeData]()
    var magnetometerDataBufffer = [MagnetometerData]()
    var motionDataBuffer = [MotionData]()
    //var locationsDataBuffer = [LocationsData]()
    
    //check if the sensors are started or not
    private var isStarted = false
    
    //set fetch interval for 5 mins, and to set sync interval as double time of fetch interval
    var isSyncNow = false
    
    //var completionHandler: ((WKBackgroundFetchResult) -> Void)?
    //var accelerometerRecorder: LMSensorRecorder
    
    static let shared = LMWatchSensorManager()
    
    private init() {

        //setup motion manager
        sensor_motionManager = MotionManager.init(MotionManager.Config().apply(closure: { [weak self] (config) in
            config.accelerometerObserver = self
            config.gyroObserver = self
            config.magnetoObserver = self
            config.motionObserver = self
            
            config.sensorTimerDelegate = self
            
            config.sensorTimerDataStoreInterval = 5.0 * 60.0//5 miunutes//
        }))
        
        //setup location
        sensor_location = LocationsSensor.init(LocationsSensor.Config().apply(closure: { config in
            //config.sensorObserver = self
            //config.minimumInterval = 1.0
            config.accuracy = kCLLocationAccuracyBestForNavigation
        }))
        
        sensorManager.addSensors([sensor_motionManager!, sensor_location!])
    }
    
    public func startSensors() {

        isStarted = true
        print("\nStart Sensors")
        stop()
        self.sensorManager.startAllSensors()
    }

    func stop() {
        sensorManager.stopAllSensors()
    }
    
    func getSensorDataRequest() -> SensorData.Request? {
        
        return SensorData.Request(sensorEvents: getSensorDataArrray())
    }
    
    func checkIsRunning() {
        print("checkIsRunning")
        if self.isStarted == false {
            if User.shared.isLogin() {//+roll
                startSensors()
                startRecorder()
                self.isStarted = true
            }
        }
        BackgroundServices.shared.performTasks()
    }
    
    func startRecorder() {
        print("startRecorder")
        //accelerometerRecorder.startReadingAccelorometerData()
    }
    
    let connection = NetworkConfig.networkingAPI()

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
    
//    @objc
//    func sensorDataPosted(_ notification: Notification) {
//        self.completionHandler?(.newData)
//        self.completionHandler = nil
//    }
    
    func fetchMagnetometerData() -> [SensorDataInfo] {

        let dataArray = magnetometerDataBufffer
        magnetometerDataBufffer.removeAll(keepingCapacity: true)

        let sensorArray = dataArray.map {
            SensorDataInfo(sensor: SensorType.lamp_magnetometer.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(magneticField: $0.magnetoData))
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
    
//    private func fetchGPSData() -> [SensorDataInfo] {
//
//        let dataArray = locationsDataBuffer
//        locationsDataBuffer.removeAll(keepingCapacity: true)
//
//        let sensorArray = dataArray.map { SensorDataInfo(sensor: SensorType.lamp_gps.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(locationData: $0)) }
//
//        return sensorArray
//    }
    
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

        let sensorArray = dataArray.map { (motionData) -> SensorDataInfo in
            
            let model = SensorDataModel(motionData: motionData)
            return SensorDataInfo(sensor: SensorType.lamp_accelerometer_motion.lampIdentifier, timestamp: motionData.timestamp, data: model)
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
//                let isLoginPreviously = User.shared.isLogin()
                User.shared.logout()
                Utils.postNotificationOnMainQueueAsync(name: .userLogOut)
//                if isLoginPreviously {
//                    WKExtension.shared().unregisterForRemoteNotifications()
//                }
            }
        }
    }
}
