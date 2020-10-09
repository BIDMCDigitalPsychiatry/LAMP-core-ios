//
//  LMSensorManager+SensorObservers.swift
//  mindLAMP Consortium
//
//  Created by ZCO Engineer on 06/03/20.
//

import Foundation
import Sensors

extension LMSensorManager: SensorStore {
    
    func timeToStore() {
        
        print("\n time to store")
        sensor_healthKit?.fetchHealthData()
        lampScreenSensor?.fetchScreenState()
        batteryLogs()
        startWatchSensors()
        DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
            let request = LMSensorManager.shared.fetchSensorDataRequest()
            SensorLogs.shared.storeSensorRequest(request)
            printToFile("\n stored file @ \(Date())")
            print("\n stored file @ \(Date())")
            BackgroundServices.shared.performTasks()
        }
    }
}

// MARK:- AccelerometerObserver
extension LMSensorManager: AccelerometerObserver {
    
    func onDataChanged(data: AccelerometerData) {
        accelerometerDataBufffer.append(data)
    }
}

// MARK:- GyroscopeObserver
extension LMSensorManager: GyroscopeObserver {
    
    func onDataChanged(data: GyroscopeData) {
        gyroscopeDataBufffer.append(data)
    }
}


// MARK: - GravityObserver
extension LMSensorManager: MotionObserver {
    
    public func onDataChanged(data: MotionData) {
        motionDataBuffer.append(data)
    }
}

// MARK:- MagnetometerObserver
extension LMSensorManager: MagnetometerObserver {
    
    func onDataChanged(data: MagnetometerData) {
        magnetometerDataBufffer.append(data)
    }
}


// MARK: - LocationsObserver
extension LMSensorManager: LocationsObserver {
    
    func onLocationChanged(data: LocationsData) {
        latestLocationsData = data
    }
    
    func onExitRegion(data: GeofenceData) {
    }
    
    func onEnterRegion(data: GeofenceData) {
    }
    
    func onVisit(data: VisitData) {
    }
    
    func onHeadingChanged(data: HeadingData) {
    }
}

// MARK:- CallsObserver
extension LMSensorManager: CallsObserver {
    func onCall(data: CallsData) {
        latestCallsData = data
    }
    
    func onRinging(number: String?) {
        print("\(#function) \n \(number ?? "nil")")
    }
    
    func onBusy(number: String?) {
        print("\(#function) \n \(number ?? "nil")")
    }
    
    func onFree(number: String?) {
        print("\(#function) \n \(number ?? "nil")")
    }
}

// MARK:- PedometerObserver
extension LMSensorManager: PedometerObserver {
    
    func onPedometerChanged(data: PedometerData) {
        latestPedometerData = data
    }
}

// MARK: - WiFiObserver
extension LMSensorManager: WiFiObserver {
    
    func onWiFiAPDetected(data: WiFiScanData) {
        latestWifiData = data
    }
    
    func onWiFiDisabled() {
        print("\(#function)")
    }
    
    func onWiFiScanStarted() {
        print("\(#function)")
    }
    
    func onWiFiScanEnded() {
        print("\(#function)")
    }
}

// MARK: - LMHealthKitSensorObserver
extension LMSensorManager: LMHealthKitSensorObserver {
    
    func onHKAuthorizationStatusChanged(success: Bool, error: Error?) {
    }
    
    func onHKDataFetch(for type: String, error: Error?) {
        let logsMessage = String(format: "\(Logs.Messages.hk_data_fetch_error)  Error: %@ for type: %@", error?.localizedDescription ?? "null", type)
        LMLogsManager.shared.addLogs(level: .error, logs: logsMessage)
    }
}
