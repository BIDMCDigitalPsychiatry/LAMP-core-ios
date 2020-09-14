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
    
    let queue = OperationQueue()
    let wristLocationIsLeft = WKInterfaceDevice.current().wristLocation == .left
    let sampleInterval = 1.0 / 50
    let rateAlongGravityBuffer = RunningBuffer(size: 50)
    
    var gravityStr = ""
    var rotationRateStr = ""
    var userAccelStr = ""
    var attitudeStr = ""
    
    var recentDetection = false

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
    
    private func getSensorDataArrray() -> [SensorDataInfo] {
        var arraySensorData = [SensorDataInfo]()

        if let data = MotionData.shared.fetchAccelerometerData() {
            arraySensorData.append(data)
        }
        if let data = MotionData.shared.fetchAccelerometerMotionData() {
            arraySensorData.append(data)
        }
        if let data = MotionData.shared.fetchGyroscopeData() {
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
        MotionData.shared.stop()
        SensorEvents().postSensorData()
//        if self.completionHandler == nil && nil != WatchSessionManager.shared.validSession {
//            WatchSessionManager.shared.updateApplicationContext(applicationContext: ["sensorData" : getSensorDataArrray()])
//        } else {
//            SensorEvents().postSensorData()
//        }
    }
    
    func sendSensorEvents(_ completionHandler: ((WKBackgroundFetchResult) -> Void)? = nil) {
        MotionData.shared.start()
        self.completionHandler = completionHandler
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.sendSensorEventsNow), userInfo: nil, repeats: false)
    }
    
    func applicationContextReceived(tuple: ApplicationContextReceived) {
        
        DispatchQueue.main.async() {
            if let loginDict = tuple.applicationContext[IOSCommands.login] as? [String: Any] {
                let loginInfo = LoginInfo(loginDict)
                Endpoint.setSessionKey(loginInfo.sessionToken)
                User.shared.login(userID: loginInfo.userId, serverAddress: loginInfo.serverAddress)
                Utils.postNotificationOnMainQueueAsync(name: .userLogined)
                //WKInterfaceDevice.current().play(.notification)
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
