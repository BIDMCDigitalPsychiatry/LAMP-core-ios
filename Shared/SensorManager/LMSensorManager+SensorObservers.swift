//
//  LMSensorManager+SensorObservers.swift
//  mindLAMP Consortium
//
//  Created by ZCO Engineer on 06/03/20.
//

import Foundation
import Sensors

extension LMSensorManager: SensorStore {
    
    @objc
    func timeToStore() {
        
        #if os(iOS)
        if lampScreenSensor?.latestScreenState?.rawValue != ScreenState.screen_locked.rawValue {
            sensor_healthKit?.fetchHealthData()
            
        } else {
            printToFile("\n Screen locked")
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
            let request = LMSensorManager.shared.getSensorDataRequest()
            self.sensor_healthKit?.clearDataArrays()
            SensorLogs.shared.storeSensorRequest(request)
            print("\n stored file -- @ \(Date())")
            if self.isSyncNow {
                print("\n sync now")
                self.isSyncNow = false
                self.startWatchSensors()
                self.batteryLogs()
                printToFile("\n stored file and sync @ \(Date())")
                BackgroundServices.shared.performTasks()
            } else {
                printToFile("\n stored file @ \(Date())")
                print("\n sync next time")
                self.isSyncNow = true
            }
        }
        #elseif os(watchOS)
        let request = getSensorDataRequest()
        SensorLogs.shared.storeSensorRequest(request)
        //send to server
        if self.isSyncNow {
            print("sync now")
            self.isSyncNow = false
            printToFile("\n stored file w @ \(Date())")
            BackgroundServices.shared.performTasks()
        } else {
            print("sync next time")
            self.isSyncNow = true
        }
        #endif
    }
}

// MARK:- AccelerometerObserver
extension LMSensorManager: AccelerometerObserver {
    
    func onDataChanged(data: AccelerometerData) {
        queueAccelerometerData.async(flags: .barrier) {
            self.accelerometerDataBufffer.append(data)
        }
    }
}

// MARK:- GyroscopeObserver
extension LMSensorManager: GyroscopeObserver {
    
    func onDataChanged(data: GyroscopeData) {
        queueGyroscopeData.async(flags: .barrier) {
            self.gyroscopeDataBufffer.append(data)
        }
    }
}


// MARK: - GravityObserver
extension LMSensorManager: MotionObserver {
    
    public func onDataChanged(data: MotionData) {
        queueMotionData.async(flags: .barrier) {
            self.motionDataBuffer.append(data)
        }
    }
}

// MARK:- MagnetometerObserver
extension LMSensorManager: MagnetometerObserver {
    
    func onDataChanged(data: MagnetometerData) {
        queueMagnetometerData.async(flags: .barrier) {
            self.magnetometerDataBufffer.append(data)
        }
    }
}


// MARK: - LocationsObserver
extension LMSensorManager: LocationsObserver {
    
    func onLocationChanged(data: LocationsData) {
        queueLocationsData.async(flags: .barrier) {
            self.locationsDataBuffer.append(data)
        }
    }
}

// MARK:- PedometerObserver
extension LMSensorManager: PedometerObserver {
    
    func onPedometerChanged(data: PedometerData) {
        queuePedometerData.async(flags: .barrier) {
            self.pedometerDataBuffer.append(data)
        }
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

#if os(iOS)
// MARK:- CallsObserver
extension LMSensorManager: CallsObserver {
    func onCall(data: CallsData) {
        print("\(#function) \n \(data)")
        queueCallsData.async(flags: .barrier) {
            self.callsDataBuffer.append(data)
        }
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

// MARK: - ScreenStateObserver
extension LMSensorManager: ScreenStateObserver {
    
    func onDataChanged(data: ScreenStateData) {
        queueScreenStateData.async(flags: .barrier) {
            self.screenStateDataBuffer.append(data)
        }
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
#endif
