//
//  LMSensorManager.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engineer on 14/01/20.
//

import Foundation
import UIKit
import HealthKit

class LMSensorManager {
    
    
    static let shared: LMSensorManager = LMSensorManager()

    
    // MARK: - VARIABLES
    var sensor_accelerometer: AccelerometerSensor?
    var sensor_bluetooth: LMBluetoothSensor?
    var sensor_calls: CallsSensor?
    var sensor_gravity: GravitySensor?
    var sensor_gyro: GyroscopeSensor?
    var sensor_healthKit: LMHealthKitSensor?
    var sensor_location: LocationsSensor?
    var sensor_magneto: MagnetometerSensor?
    var sensor_rotation: RotationSensor?
    //var sensor_screen: ScreenSensor?
    var sensor_wifi: WiFiSensor?
    var sensor_pedometer: PedometerSensor?
    var lampScreenSensor: LampScreenSensor?

    var sensorApiTimer: Timer?
    
    // SensorData storage variables.
    var latestLocationsData: LocationsData?
    var latestPedometerData: PedometerData?
    var latestCallsData: CallsData?
    var latestWifiData: WiFiScanData?
    //var latestScreenStateData: ScreenStateData
    
    var watchSensorData: [SensorDataInfo]?
    
    private init() { }
    
    private func initiateSensors() {
        setupAccelerometerSensor()
        setupBluetoothSensor()
        setupCallsSensor()
        setuGravitySensor()
        setupGyroscopeSensor()
        setupHealthKitSensor()
        setupLocationSensor()
        setupMagnetometerSensor()
        setupPedometerSensor()
        setupRotationSensor()
        setupScreenSensor()
        setupWifiSensor()
    }
    
    private func deinitSensors() {
        sensor_accelerometer = nil
        sensor_bluetooth = nil
        sensor_calls = nil
        sensor_gravity = nil
        sensor_gyro = nil
        sensor_healthKit = nil
        sensor_location = nil
        sensor_magneto = nil
        sensor_pedometer = nil
        sensor_rotation = nil
        //sensor_screen = nil
        sensor_wifi = nil
        lampScreenSensor = nil
    }


    private func startAllSensors() {

        sensor_accelerometer?.start()
        sensor_bluetooth?.start()
        sensor_calls?.start()
        sensor_gravity?.start()
        sensor_gyro?.start()
        sensor_healthKit?.start()
        sensor_location?.start()
        sensor_magneto?.start()
        sensor_pedometer?.start()
        sensor_rotation?.start()
        //sensor_screen?.start()
        sensor_wifi?.start()
        lampScreenSensor?.start()
    }
    
    private func stopAllSensors() {
        sensor_accelerometer?.stop()
        sensor_bluetooth?.stop()
        sensor_calls?.stop()
        sensor_gravity?.stop()
        sensor_gyro?.stop()
        sensor_healthKit?.stop()
        sensor_location?.stop()
        sensor_magneto?.stop()
        sensor_pedometer?.stop()
        sensor_rotation?.stop()
        //sensor_screen?.stop()
        sensor_wifi?.stop()
        lampScreenSensor?.stop()
    }
    
    private func refreshAllSensors() {
        stopAllSensors()
        startAllSensors()
    }
    
    
    private func startTimer() {
        //Initial timer so as to post first set of sensorData. This timer invalidates after it fires.
        Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(postSensorData), userInfo: nil, repeats: false)
        //Repeating timer which invokes postSensorData method at given interval of time.
        sensorApiTimer = Timer.scheduledTimer(timeInterval: 10*60, target: self, selector: #selector(postSensorData), userInfo: nil, repeats: true)
    }

    private func stopTimer() {
        sensorApiTimer?.invalidate()
    }
    
    @objc func postSensorData() {
        sensor_healthKit?.fetchHealthData()
        lampScreenSensor?.fetchScreenState()
        batteryLogs()
        startWatchSensors()
        //Delay given so as to fetch the HealthKit data.
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            BackgroundServices.shared.performTasks()
        }
    }
    
    func startWatchSensors() {
        //clear all existing data
        watchSensorData?.removeAll()
        //send a message to watch to collect sensor data
        let messageInfo: [String: Any] = [IOSCommands.sendWatchSensorEvents : true, "timestamp" : Date().timeInMilliSeconds]
        WatchSessionManager.shared.updateApplicationContext(applicationContext: (messageInfo))
    }
    
    /// To start sensors observing.
    func startSensors() {
        initiateSensors()
        startAllSensors()
        startTimer()
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    /// To stop sensors observing.
    func stopSensors() {
        stopTimer()
        stopAllSensors()
        deinitSensors()
    }
    
    // MARK: - SENSOR SETUP METHODS
    
    func setupAccelerometerSensor() {
        sensor_accelerometer = AccelerometerSensor.init(AccelerometerSensor.Config().apply{ config in
            config.sensorObserver = self
            config.frequency = 1
        })
    }
    
    func setupBluetoothSensor() {
        sensor_bluetooth = LMBluetoothSensor()
    }
    
    func setupCallsSensor() {
        sensor_calls = CallsSensor.init(CallsSensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
    }
    
    func setuGravitySensor() {
        sensor_gravity = GravitySensor.init(GravitySensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
    }
    
    func setupGyroscopeSensor() {
        sensor_gyro = GyroscopeSensor.init(GyroscopeSensor.Config().apply(closure: { config in
            config.sensorObserver = self
            config.frequency = 1
        }))
    }
    
    func setupHealthKitSensor() {
        sensor_healthKit = LMHealthKitSensor()
        sensor_healthKit?.observer = self
    }

    func setupLocationSensor() {
        sensor_location = LocationsSensor.init(LocationsSensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
    }
    
    func setupMagnetometerSensor() {
        sensor_magneto = MagnetometerSensor.init(MagnetometerSensor.Config().apply(closure: { config in
            config.sensorObserver = self
            config.frequency = 1
        }))
    }
    
    func setupPedometerSensor() {
        sensor_pedometer = PedometerSensor.init(PedometerSensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
    }
    
    func setupRotationSensor() {
        sensor_rotation = RotationSensor.init(RotationSensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
    }
    
    func setupScreenSensor() {
        lampScreenSensor = LampScreenSensor()
//        sensor_screen = ScreenSensor.init(ScreenSensor.Config().apply(closure: { config in
//            config.sensorObserver = self
//        }))
    }
    
    func setupWifiSensor() {
        sensor_wifi = WiFiSensor.init(WiFiSensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
    }
}
extension LMSensorManager {
        
    func fetchSensorDataRequest() -> SensorData.Request {
        var arraySensorData = [SensorDataInfo]()
        
        if let data = fetchAccelerometerData() {
            arraySensorData.append(data)
        }
        if let data = fetchAccelerometerMotionData() {
            arraySensorData.append(data)
        }
        if let data = fetchGyroscopeData() {
            arraySensorData.append(data)
        }
        if let data = fetchMagnetometerData() {
            arraySensorData.append(data)
        }
        if let data = fetchGPSData() {
            arraySensorData.append(data)
        }
        if let data = fetchBluetoothData() {
            arraySensorData.append(data)
        }
        printToFile("fetch screenstate")
        if let data = fetchScreenStateData() {
            arraySensorData.append(data)
        } else {
            printToFile("no screen data")
        }
        if let data = fetchCallsData() {
            arraySensorData.append(data)
        }
        if let data = fetchWiFiData() {
            arraySensorData.append(data)
        }
        if let data = fetchWorkoutSegmentData() {
            arraySensorData.append(data)
        }

        if let data = fetchPedometerData() {
            arraySensorData.append(contentsOf: data)
        }

        if let data = fetchHealthKitQuantityData() {
            arraySensorData.append(contentsOf: data)
        }
        if let data = fetchHKCategoryData() {
            arraySensorData.append(contentsOf: data)
        }

        if let data = fetchHKCharacteristicData() {
            arraySensorData.append(contentsOf: data)
        }
        
        //append watch sensor data
        if let watchData = watchSensorData {
            arraySensorData.append(contentsOf: watchData)
        }
        
        return SensorData.Request(sensorEvents: arraySensorData)
    }
    
    private func fetchAccelerometerData() -> SensorDataInfo? {
        guard let data = sensor_accelerometer?.latestData() else {
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.accelerometer_null)
            return nil
        }
        var model = SensorDataModel()
        model.x = data.x
        model.y = data.y
        model.z = data.z

        return SensorDataInfo(sensor: SensorType.lamp_accelerometer.jsonKey, timestamp: Double(data.timestamp), data: model)
    }
    
    private func fetchAccelerometerMotionData() -> SensorDataInfo? {
        
        let timeStamp = Date().timeInMilliSeconds
        var model = SensorDataModel()
        
        if let data = sensor_accelerometer?.latestData() {
            var motion = Motion()
            motion.x = data.x
            motion.y = data.y
            motion.z = data.z
            
            model.motion = motion
        }
//        else {
//            LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.accelerometer_null)
//        }
        if let data = sensor_gravity?.latestData() {
            var gravity = Gravitational()
            gravity.x = data.x
            gravity.y = data.y
            gravity.z = data.z
            
            model.gravity = gravity
        }
//        else {
//            LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.gravity_null)
//        }
        if let data = sensor_rotation?.latestData() {
            var rotation = Rotational()
            rotation.x = data.x
            rotation.y = data.y
            rotation.z = data.z
            
            model.rotation = rotation
        }
//        else {
//            LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.rotation_null)
//        }
        if let data = sensor_magneto?.latestData() {
            var magnetic = Magnetic()
            magnetic.x = data.x
            magnetic.y = data.y
            magnetic.z = data.z
            
            model.magnetic = magnetic
        }
//        else {
//            LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.magnetometer_null)
//        }
        
        return SensorDataInfo(sensor: SensorType.lamp_accelerometer_motion.jsonKey, timestamp: timeStamp, data: model)
    }
    
    private func fetchGyroscopeData() -> SensorDataInfo? {
        guard let data = sensor_gyro?.latestData() else {
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.gyroscope_null)
            return nil
        }
        var model = SensorDataModel()
        model.x = data.x
        model.y = data.y
        model.z = data.z

        return SensorDataInfo(sensor: SensorType.lamp_gyroscope.jsonKey, timestamp: Double(data.timestamp), data: model)
    }
    
    private func fetchMagnetometerData() -> SensorDataInfo? {
        guard let data = sensor_magneto?.latestData() else {
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.magnetometer_null)
            return nil
        }
        var model = SensorDataModel()
        model.x = data.x
        model.y = data.y
        model.z = data.z

        return SensorDataInfo(sensor: SensorType.lamp_magnetometer.jsonKey, timestamp: Double(data.timestamp), data: model)
    }
        
//    private func fetchSleepData() -> SensorDataInfo? {
//        guard let arrData = sensor_healthKit?.latestCategoryData() else { return nil }
//        guard let data = latestData(for: HKCategoryTypeIdentifier.sleepAnalysis, in: arrData) else { return nil }
//
//        var model = SensorDataModel()
//        model.value = data.value
//        //model.valueString = data.valueText
//        model.startDate = data.startDate
//        model.endDate = data.endDate
//
//        return SensorDataInfo(sensor: HKCategoryTypeIdentifier.sleepAnalysis.jsonKey, timestamp: Double(data.timestamp), data: model)
//    }
    
    private func fetchPedometerData() -> [SensorDataInfo]? {
        
        var arrayData = [SensorDataInfo]()
        guard let data = latestPedometerData else {
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.pedometer_steps_null)
            return nil
        }
        var stepsModel = SensorDataModel()
        stepsModel.value = Double(data.numberOfSteps)
        let stpsData = SensorDataInfo(sensor: SensorType.lamp_steps.jsonKey, timestamp: Double(data.timestamp), data: stepsModel)
        arrayData.append(stpsData)
        
        var flightModel = SensorDataModel()
        flightModel.value = Double(data.floorsAscended)
        arrayData.append(SensorDataInfo(sensor: SensorType.lamp_flights_up.jsonKey, timestamp: Double(data.timestamp), data: flightModel))

        var distanceModel = SensorDataModel()
        distanceModel.value = data.distance
        arrayData.append(SensorDataInfo(sensor: SensorType.lamp_distance.jsonKey, timestamp: Double(data.timestamp), data: distanceModel))
        
        var descendedModel = SensorDataModel()
        descendedModel.value = Double(data.floorsDescended)
        arrayData.append(SensorDataInfo(sensor: SensorType.lamp_flights_down.jsonKey, timestamp: Double(data.timestamp), data: distanceModel))
        
        var currentPaceModel = SensorDataModel()
        currentPaceModel.value = data.currentPace
        arrayData.append(SensorDataInfo(sensor: SensorType.lamp_currentPace.jsonKey, timestamp: Double(data.timestamp), data: currentPaceModel))
        
        var currentCadenceModel = SensorDataModel()
        currentCadenceModel.value = data.currentCadence
        arrayData.append(SensorDataInfo(sensor: SensorType.lamp_currentCadence.jsonKey, timestamp: Double(data.timestamp), data: currentCadenceModel))
        
        var averageActivePaceModel = SensorDataModel()
        averageActivePaceModel.value = data.averageActivePace
        arrayData.append(SensorDataInfo(sensor: SensorType.lamp_avgActivePace.jsonKey, timestamp: Double(data.timestamp), data: averageActivePaceModel))
        
        return arrayData
    }


    
//    private func fetchGPSContextualData() -> SensorDataModel? {
//        guard let data = latestLocationsData else {
//            LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.location_null)
//            return nil
//        }
//        var model = SensorDataModel()
//        model.longitude = data.longitude
//        model.latitude = data.latitude
//
//        return sensorDataRequest(with: Double(data.timestamp), sensor: SensorType.lamp_gps_contextual, dataModel: model)
//    }
    
    private func fetchGPSData() -> SensorDataInfo? {
        guard let data = latestLocationsData else {
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.location_null)
            return nil
        }
        var model = SensorDataModel()
        model.longitude = data.longitude
        model.latitude = data.latitude
        model.altitude = data.altitude

        return SensorDataInfo(sensor: SensorType.lamp_gps.jsonKey, timestamp: Double(data.timestamp), data: model)
    }
    
    private func fetchBluetoothData() -> SensorDataInfo? {
        guard let data = sensor_bluetooth?.latestData() else {
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.bluetooth_null)
            return nil
        }
        var model = SensorDataModel()
        model.bt_address = data.address
        model.bt_name = data.name
        model.bt_rssi = data.rssi

        return SensorDataInfo(sensor: SensorType.lamp_bluetooth.jsonKey, timestamp: data.timestamp, data: model)
    }
    
    private func fetchWiFiData() -> SensorDataInfo? {
        guard let data = latestWifiData else {
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.wifi_null)
            return nil
        }
        var model = SensorDataModel()
        model.bssid = data.bssid
        model.ssid = data.ssid

        return SensorDataInfo(sensor: SensorType.lamp_wifi.jsonKey, timestamp: Double(data.timestamp), data: model)
    }
    
    private func fetchScreenStateData() -> SensorDataInfo? {
        
        guard let data = lampScreenSensor?.latestScreenStateData else {
            return nil
        }
        var model = SensorDataModel()
        model.value = Double(data.screenState.rawValue)
        model.valueString = data.screenState.stringValue

        return SensorDataInfo(sensor: SensorType.lamp_screen_state.jsonKey, timestamp: data.timestamp, data: model)
    }
    
    private func fetchCallsData() -> SensorDataInfo? {
        guard let data = latestCallsData else {
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.calls_null)
            return nil
        }
        var model = SensorDataModel()
        model.call_type = data.type
        model.call_duration = Double(data.duration)
        model.call_trace = data.trace

        return SensorDataInfo(sensor: SensorType.lamp_calls.jsonKey, timestamp: Double(data.timestamp), data: model)
    }
    
    private func fetchWorkoutSegmentData() -> SensorDataInfo? {
        guard let arrData = sensor_healthKit?.latestWorkoutData() else {
            return nil
        }
        guard let data = arrData.max(by: { ($0.endDate ?? 0) < ($1.endDate ?? 0) }) else {
            return nil
        }
        var model = SensorDataModel()
        model.workout_type = data.type
        model.workout_durtion = data.value
        model.startDate = data.startDate
        model.endDate = data.endDate
        
        return SensorDataInfo(sensor: SensorType.lamp_segment.jsonKey, timestamp: Double(data.timestamp), data: model)
    }
}

extension LMSensorManager {
    
    func sensorDataRequest(with timestamp: Double = Date().timeInMilliSeconds, sensor: SensorType, dataModel: SensorDataModel) -> SensorDataInfo {
        
        return SensorDataInfo(sensor: sensor.jsonKey, timestamp: timestamp, data: dataModel)
    }
    
    func fetchHKCharacteristicData() -> [SensorDataInfo]? {
        
        guard let arrData = sensor_healthKit?.latestCharacteristicData() else {
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.hkcharacteristic_null)
            return nil
        }

        return arrData.map { (healthData) -> SensorDataInfo in
            var data = SensorDataModel()
            data.value = healthData.value
            data.valueString = healthData.valueText
            data.startDate = healthData.startDate
            data.endDate = healthData.endDate
            return SensorDataInfo(sensor: healthData.lampIdentifier, timestamp: Double(healthData.timestamp), data: data)
        }
        
    }
    
    func fetchHKCategoryData() -> [SensorDataInfo]? {
        
        guard let arrData = sensor_healthKit?.latestCategoryData() else {
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.hkquantity_null)
            return nil
        }
        var arrayData = [SensorDataInfo]()
        guard let categoryTypes: [HKCategoryTypeIdentifier] = sensor_healthKit?.healthCategoryTypes.map( {HKCategoryTypeIdentifier(rawValue: $0.identifier)} ) else { return nil }
        for categoryType in categoryTypes {
            switch categoryType {
            default:
                if let data = latestData(for: categoryType, in: arrData) {
                    var model = SensorDataModel()
                    model.unit = data.unit
                    model.value = data.value
                    model.valueString = data.valueText
                    model.startDate = data.startDate
                    model.endDate = data.endDate
                    arrayData.append(SensorDataInfo(sensor: categoryType.jsonKey, timestamp: Double(data.timestamp), data: model))
                }
//                else {
//                    let msg = String(format: Logs.Messages.quantityType_null, categoryType.jsonKey)
//                    LMLogsManager.shared.addLogs(level: .warning, logs: msg)
//                }
            }
        }
        return arrayData
    }
    
    func fetchHealthKitQuantityData() -> [SensorDataInfo]? {
        guard let arrData = sensor_healthKit?.latestQuantityData() else {
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.hkquantity_null)
            return nil
        }
        var arrayData = [SensorDataInfo]()
        
        guard let quantityTypes: [HKQuantityTypeIdentifier] = sensor_healthKit?.healthQuantityTypes.map( {HKQuantityTypeIdentifier(rawValue: $0.identifier)} ) else { return nil }
        for quantityType in quantityTypes {
            switch quantityType {
                
            case .bloodPressureSystolic:
                if let dataDiastolic = latestData(for: HKQuantityTypeIdentifier.bloodPressureDiastolic, in: arrData), let dataSystolic = latestData(for: HKQuantityTypeIdentifier.bloodPressureSystolic, in: arrData) {
                    var model = SensorDataModel()
                    model.unit = dataDiastolic.unit
                    if let diastolic = dataDiastolic.value {
                        model.bp_diastolic = diastolic
                    }
                    if let systolic = dataSystolic.value {
                        model.bp_systolic = systolic
                    }
                    model.startDate = dataSystolic.startDate
                    model.endDate = dataSystolic.endDate
                    arrayData.append(SensorDataInfo(sensor: quantityType.jsonKey, timestamp: Double(dataDiastolic.timestamp), data: model))
                } else {
                    //let msg = String(format: Logs.Messages.quantityType_null, quantityType.jsonKey)
                    //LMLogsManager.shared.addLogs(level: .warning, logs: msg)
                }
            case .bloodPressureDiastolic:
                ()//handled with Systolic
            default://bodyMass, height, respiratoryRate, heartRate
                if let data = latestData(for: quantityType, in: arrData) {
                    var model = SensorDataModel()
                    model.unit = data.unit
                    model.value = data.value
                    model.startDate = data.startDate
                    model.endDate = data.endDate
                    arrayData.append(SensorDataInfo(sensor: quantityType.jsonKey, timestamp: Double(data.timestamp), data: model))
                } else {
                    //let msg = String(format: Logs.Messages.quantityType_null, quantityType.jsonKey)
                    //LMLogsManager.shared.addLogs(level: .warning, logs: msg)
                }
            }
        }
        return arrayData
    }
    
    func latestData(for hkIdentifier: HKCategoryTypeIdentifier, in array: [LMHealthKitSensorData]) -> LMHealthKitSensorData? {
        return array.filter({ $0.type == hkIdentifier.rawValue }).max(by: {($0.endDate ?? 0) < ($1.endDate ?? 0) })
    }
    func latestData(for hkIdentifier: HKQuantityTypeIdentifier, in array: [LMHealthKitSensorData]) -> LMHealthKitSensorData? {
        return array.filter({ $0.type == hkIdentifier.rawValue }).max(by: {($0.endDate ?? 0) < ($1.endDate ?? 0) })
    }
    
}

extension LMSensorManager {
    
    private func batteryLogs() {
        guard isBatteryLevelLow() else { return }
        LMLogsManager.shared.addLogs(level: .info, logs: Logs.Messages.battery_low)
    }
    
    private func isBatteryLevelLow(than level: Float = 20) -> Bool {
        return UIDevice.current.batteryLevel < level/100
    }
}

extension LMSensorManager: iOSDelegate {
    
    func messageReceived(tuple: MessageReceived) {
//        // Handle receiving message
//        printDebug("messageReceived on phone \(tuple.message)")
//        if let sensorData = tuple.message[SharingInfo.Keys.watchSensorDataArray.rawValue] as? Data {
//            let decoder = JSONDecoder()
//            do {
//                watchSensorData = try decoder.decode([SensorDataInfo].self, from: sensorData)
//            } catch let error {
//                printError("messageReceived" + error.localizedDescription)
//            }
//        } else if let _ = tuple.message[SharingInfo.Keys.fetchLoginInfoFromPhone.rawValue] as? Bool {
//            //Inform watch the login info
//            guard let userID = User.shared.userId else {return}
//            guard let sessionToken = Endpoint.getSessionKey() else {return}
//            var messageInfo: [String: Any] = [SharingInfo.Keys.userId.rawValue : userID]
//            messageInfo[SharingInfo.Keys.sessionToken.rawValue] = sessionToken
//            tuple.replyHandler?(messageInfo)
//        }
    }
    
    func applicationContextReceived(tuple: ApplicationContextReceived) {
//        printDebug("messageReceived on phonef \(tuple.applicationContext)")
//        if let _ = tuple.applicationContext[SharingInfo.Keys.fetchLoginInfoFromPhone.rawValue] as? Bool {
//            //Inform watch the login info
//            guard let userID = User.shared.userId else {return}
//            guard let sessionToken = Endpoint.getSessionKey() else {return}
//            var messageInfo: [String: Any] = [SharingInfo.Keys.userId.rawValue : userID]
//            messageInfo[SharingInfo.Keys.sessionToken.rawValue] = sessionToken
//
//            WatchSessionManager.shared.updateApplicationContext(applicationContext: messageInfo)
//
//        }
    }
}
