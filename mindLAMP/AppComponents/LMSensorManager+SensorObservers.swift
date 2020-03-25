//
//  LMSensorManager+SensorObservers.swift
//  mindLAMP
//
//  Created by ZCO Engineer on 06/03/20.
//

import Foundation

// MARK:- AccelerometerObserver
extension LMSensorManager: AccelerometerObserver {
    
    func onDataChanged(data: AccelerometerData) {
    }
}

// MARK:- GyroscopeObserver
extension LMSensorManager: GyroscopeObserver {
    
    func onDataChanged(data: GyroscopeData) {
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

// MARK:- ScreenObserver
extension LMSensorManager: ScreenObserver {
    public func onScreenOn() {
        latestScreenStateData = ScreenStateData(screenState: .screen_on)
    }
    
    public func onScreenOff() {
        latestScreenStateData = ScreenStateData(screenState: .screen_off)
    }
    
    public func onScreenLocked() {
        latestScreenStateData = ScreenStateData(screenState: .screen_locked)
    }
    
    public func onScreenUnlocked() {
        latestScreenStateData = ScreenStateData(screenState: .screen_unlocked)
    }
    
    public func onScreenBrightnessChanged(data: ScreenBrightnessData) {
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

// MARK: - GravityObserver
extension LMSensorManager: GravityObserver {
    
    public func onDataChanged(data: GravityData) {
    }
}

// MARK:- MagnetometerObserver
extension LMSensorManager: MagnetometerObserver {
    
    func onDataChanged(data: MagnetometerData) {
    }
}

// MARK:- PedometerObserver
extension LMSensorManager: PedometerObserver {
    
    func onPedometerChanged(data: PedometerData) {
        latestPedometerData = data
    }
}

// MARK: - RotationObserver
extension LMSensorManager: RotationObserver {
    
    func onDataChanged(data: RotationData) {
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
