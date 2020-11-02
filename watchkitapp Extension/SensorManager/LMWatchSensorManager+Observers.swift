// watchkitapp Extension

import Foundation
import Sensors

//// MARK: - LocationsObserver
//extension LMWatchSensorManager: LocationsObserver {
//    
//    func onLocationChanged(data: LocationsData) {
//        locationsDataBuffer.append(data)
//    }
//}

// MARK: - GyroscopeObserver
extension LMWatchSensorManager: GyroscopeObserver {
    
    public func onDataChanged(data: GyroscopeData) {
        gyroscopeDataBufffer.append(data)
    }
}


//// MARK: - AccelerometerObserver
extension LMWatchSensorManager: AccelerometerObserver {

    public func onDataChanged(data: AccelerometerData) {
        accelerometerDataBufffer.append(data)
    }
}

// MARK: - MotionObserver
extension LMWatchSensorManager: MotionObserver {
    
    public func onDataChanged(data: MotionData) {
        motionDataBuffer.append(data)
    }
}

// MARK:- MagnetometerObserver
extension LMWatchSensorManager: MagnetometerObserver {

    func onDataChanged(data: MagnetometerData) {
        
        magnetometerDataBufffer.append(data)
    }
}
extension LMWatchSensorManager: SensorStore {
    func timeToStore() {
        guard let request = getSensorDataRequest() else { return }
        SensorLogs.shared.storeSensorRequest(request)
        //send to server
        if self.isSyncNow {
            print("sync now")
            self.isSyncNow = false
            printToFile("\n stored file @ \(Date())")
            BackgroundServices.shared.performTasks()
        } else {
            print("sync next time")
            self.isSyncNow = true
        }
    }
}
