//
//  LMSensorManager+SensorObservers.swift
//  mindLAMP Consortium
//
//  Created by ZCO Engineer on 06/03/20.
//

import Foundation
import LAMP
import UIKit

extension LMSensorManager: SensorStore {
    
    @objc
    func timeToStore() {
//        let dateStr = dateFormatter.string(from: Date())
//        
//        print("fetch now \(dateStr)")
        #if os(iOS)
        if lampScreenSensor?.latestScreenState?.rawValue != ScreenState.screen_locked.rawValue {
            sensor_healthKit?.fetchHealthData()
        } else {
            printToFile("Screen locked")
        }
        //SensorKit data fetch
        sensorLoader?.fetchData()
        
        DispatchQueue.main.async {
            (UIApplication.shared.delegate as? AppDelegate)?.calculateBadgeCount()
        }
        sensor_wifi?.startScanning()

        //set 15 seconds delay to fetch all healthkit data
        printToFile("15 seconds delay")
        DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
            printToFile("----")
            self.sensor_wifi?.stopScanning()
            if self.sensor_location == nil {
                printToFile("\ndeallocated")
                return } //stop syncing if sensors are stopped
            printToFile("--syncToServer--")
            self.syncToServer()
        }
        #elseif os(watchOS)
        syncToServer()
        #endif
    }
    
    func syncToServer() {
        if let request = self.getSensorDataRequest() {
            SensorLogs.shared.storeSensorRequest(request)//store to disk
            print("stored file -- @ \(Date())")
        } else {
            print("no file to store")
        }
        #if os(iOS)
        if let request = self.getSensorKitRequest() {
            print("write to file \(request.count)")
            SensorLogs.shared.storeSensorKitRequest(request)//store to disk
            print("stored file -- @ \(Date())")
        } else {
            print("no file to store")
        }
        #endif
        //check battery state
        guard BatteryState.shared.isLowPowerEnabled == false else {
            printToFile("isLowPowerEnabled")
            return }
        
        //syncing to server for alternate fetch.
        if self.isSyncNow {
            self.isSyncNow = false
            self.startWatchSensors()
            
            printToFile("stored file and sync @ \(Date())")
            if isOktoSync() {
                BackgroundServices.shared.performTasks()
            }
        } else {
            //Check ActivityAPI sync here
            #if os(iOS)
            DispatchQueue.main.async {
                let appdelegate = UIApplication.shared.delegate as! AppDelegate
                let navController = appdelegate.window?.rootViewController as? UINavigationController
                (navController?.topViewController as? HomeViewController)?.scheduleHandler.refreshActivities()
            }
            refreshSensorSpecs() // not for watch ???
            #endif
            
            printToFile("stored file @ \(Date())")
            self.isSyncNow = true
        }
    }
}

// SensorKitCallbacks

#if os(iOS)
extension LMSensorManager: SensorKitObserver {
    func onSensorKitError(_ errType: Error) {
        DispatchQueue.main.async {
            self.showSensorKitAlert(errType)
        }
    }
    
    func onSensorFetch(_ fetchedData: SensorKitEvent) {
        
        queueSensorKitBufferData.async(flags: .barrier) { [weak self] in
            self?.sensorKitDataBuffer.append(fetchedData)
        }
    }
    func showSensorKitAlert(_ error: Error) {
        #if os(iOS)
        let alertController = UIAlertController(title: "Research Sensor & Usage Data Permission Required", message: "Please enable permissions in Settings -> Privacy -> Research Senspr & Usage Data.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Settings", style: .default, handler: {(cAlertAction) in
            //Redirect to Settings app
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        alertController.addAction(okAction)
        
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        appdelegate.window?.rootViewController?.present(alertController, animated: true, completion: nil)
        #endif
    }
}
#endif


// MARK:- ActivitySensorObserver
extension LMSensorManager: ActivitySensorObserver {
    
    func onDataChanged(data: ActivityData) {
        queueActivityData.async(flags: .barrier) {
            self.activityDataBuffer.append(data)
        }
    }
}

// MARK:- AccelerometerObserver
extension LMSensorManager: AccelerometerObserver {
    
    func onDataChanged(data: AccelerometerData) {
        //let accDate = Date.init(timeIntervalSince1970: data.timestamp/1000)
        //printToFile("AccelerometerData \(dateFormatter.string(from: Date())), \(data.timestamp)")
        queueAccelerometerData.async(flags: .barrier) {
            self.accelerometerDataBufffer.append(data)
        }
    }
}

//// MARK:- GyroscopeObserver
//extension LMSensorManager: GyroscopeObserver {
//    
//    func onDataChanged(data: GyroscopeData) {
//        queueGyroscopeData.async(flags: .barrier) {
//            self.gyroscopeDataBufffer.append(data)
//        }
//    }
//}


// MARK: - GravityObserver
extension LMSensorManager: MotionObserver {
    
    public func onDataChanged(data: MotionData) {
        queueMotionData.async(flags: .barrier) {
            self.motionDataBuffer.append(data)
        }
    }
}

//// MARK:- MagnetometerObserver
//extension LMSensorManager: MagnetometerObserver {
//    
//    func onDataChanged(data: MagnetometerData) {
//        queueMagnetometerData.async(flags: .barrier) {
//            self.magnetometerDataBufffer.append(data)
//        }
//    }
//}

// MARK: - LocationsDataObserver
extension LMSensorManager: LocationsDataObserver {
    
    func onLocationChanged(data: LocationsData) {
        queueLocationsData.async(flags: .barrier) {
            self.locationsDataBuffer.append(data)
        }
    }
}

// MARK: - LocationsObserver
extension LMSensorManager: LocationsObserver {

    func onError(_ errType: LocationErrorType) {
        switch errType {

        case .notEnabled, .denied:
            //post as sensor data
            let data = SensorDataModel(action: SensorType.AnalyticAction.logs.rawValue, userAgent: UserAgent.defaultAgent, errorMsg: Logs.Messages.gps_off)
            let events = [SensorEvent(timestamp: Date().timeInMilliSeconds, sensor: SensorType.lamp_analytics.lampIdentifier, data: data)]
            let request = SensorData.Request(sensorEvents: events)
            SensorLogs.shared.storeSensorRequest(request, fileNameWithoutExt: "gps_off")//store to disk
            
            //LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.gps_off)
            DispatchQueue.main.async {
                self.showLocationAlert()
            }
        case .otherErrors(let error):
            //post as sensor data
            let msg = String(format: Logs.Messages.location_error, error.localizedDescription)
            let data = SensorDataModel(action: SensorType.AnalyticAction.logs.rawValue, userAgent: UserAgent.defaultAgent, errorMsg: msg)
            let events = [SensorEvent(timestamp: Date().timeInMilliSeconds, sensor: SensorType.lamp_analytics.lampIdentifier, data: data)]
            let request = SensorData.Request(sensorEvents: events)
            SensorLogs.shared.storeSensorRequest(request)//store to disk
            
            //let msg = String(format: Logs.Messages.location_error, error.localizedDescription)
            //LMLogsManager.shared.addLogs(level: .error, logs: msg)
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
        
        //post as sensor data
        //https://github.com/BIDMCDigitalPsychiatry/LAMP-platform/issues/280
//        let logsMessage = String(format: "\(Logs.Messages.hk_data_fetch_error) %@", error?.localizedDescription ?? "null")
//        let data = SensorDataModel(action: SensorType.AnalyticAction.logs.rawValue, userAgent: UserAgent.defaultAgent, errorMsg: logsMessage)
//        let events = [SensorEvent(timestamp: Date().timeInMilliSeconds, sensor: SensorType.lamp_analytics.lampIdentifier, data: data)]
//        let request = SensorData.Request(sensorEvents: events)
//        SensorLogs.shared.storeSensorRequest(request, fileNameWithoutExt: type)//store to disk
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
