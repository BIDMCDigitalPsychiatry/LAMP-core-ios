// watchkitapp Extension

import Foundation
import Sensors

// MARK: - GyroscopeObserver
extension LMWatchSensorManager: GyroscopeObserver {
    
    public func onDataChanged(data: GyroscopeData) {
        gyroscopeDataBufffer.append(data)
    }
}


// MARK: - AccelerometerObserver
extension LMWatchSensorManager: AccelerometerObserver {
    
    public func onDataChanged(data: AccelerometerData) {
        accelerometerDataBufffer.append(data)
    }
}

// MARK: - GravityObserver
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
    func timeToStore(_ runCount: Int) {
        let request = getSensorDataRequest()
        SensorLogs.shared.storeSensorRequest(request)
        //send to server
        if runCount % 2 == 0 {
            BackgroundServices.shared.performTasks()
        }
    }
}
