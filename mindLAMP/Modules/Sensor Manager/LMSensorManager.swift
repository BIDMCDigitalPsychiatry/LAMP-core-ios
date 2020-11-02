//
//  LMSensorManager.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engineer on 14/01/20.
//

import Foundation
import UIKit
#if os(iOS)
import HealthKit
#endif
import Sensors

class LMSensorManager {
    
    //singleton object
    static let shared: LMSensorManager = LMSensorManager()
    
    //manager to hold all sensor references
    private let sensorManager = SensorManager()
    
    var sensor_motionManager: MotionManager?
    var sensor_location: LocationsSensor?
    var sensor_calls: CallsSensor?
    var lampScreenSensor: ScreenSensor?
    
    var sensor_bluetooth: LMBluetoothSensor?
    var sensor_healthKit: LMHealthKitSensor?
    var sensor_wifi: WiFiSensor?
    var sensor_pedometer: PedometerSensor?
    

    //TImer to post data to server
    var sensorApiTimer: Timer?
    
    // SensorData storage variables for motion sensors.
    var accelerometerDataBufffer = [AccelerometerData]()
    var gyroscopeDataBufffer = [GyroscopeData]()
    var magnetometerDataBufffer = [MagnetometerData]()
    var motionDataBuffer = [MotionData]()
    
    // SensorData storage variables for other sensors
    var locationsDataBuffer = [LocationsData]()
    var callsDataBuffer = [CallsData]()
    var screenStateDataBuffer = [ScreenStateData]()
    
    var latestPedometerData: PedometerData?
    var latestWifiData: WiFiScanData?

    //check if the sensors are started or not
    private var isStarted = false
    
    //set fetch interval for 5 mins, and to set sync interval as double time of fetch interval
    var isSyncNow = false
    
    private init() {
        
        #if os(iOS)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        #endif
    }
    
    deinit {
        #if os(iOS)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didEnterBackgroundNotification,
                                                  object: nil)
        #endif
    }
    
    @objc private func appDidEnterBackground() {
        //sensor_motionManager?.restartMotionUpdates(). this is doing inside the motion sensor class
        sensor_location?.locationManager.stopMonitoringSignificantLocationChanges()
        sensor_location?.locationManager.startMonitoringSignificantLocationChanges()
    }
    
    private func initiateSensors() {
        
        #if os(iOS)
        setUpSensorMotionManager()
        setupLocationSensor()
        setupCallsSensor()
        setupScreenSensor()
        
        setupBluetoothSensor()
        setupHealthKitSensor()
        setupPedometerSensor()
        setupWifiSensor()
        #elseif os(watchOS)
        setUpSensorMotionManager()
        #endif
        
    }
    
    private func deinitSensors() {
        
        sensor_motionManager = nil
        sensor_bluetooth = nil
        sensor_calls = nil
        sensor_healthKit = nil
        sensor_location = nil
        sensor_pedometer = nil
        //sensor_screen = nil
        sensor_wifi = nil
        lampScreenSensor = nil
    }
    
    
    private func startAllSensors() {
        
        sensorManager.startAllSensors()
    }
    
    private func stopAllSensors() {
        
        sensorManager.stopAllSensors()
    }
    
    private func refreshAllSensors() {
        sensorManager.stopAllSensors()
        sensorManager.startAllSensors()
    }
    
    
    private func startTimer() {
        //Initial timer so as to post first set of sensorData. This timer invalidates after it fires.
        Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(timeToStore), userInfo: nil, repeats: false)
        //Repeating timer which invokes postSensorData method at given interval of time.
        sensorApiTimer = Timer.scheduledTimer(timeInterval: 10*60, target: self, selector: #selector(timeToStore), userInfo: nil, repeats: true)
    }
    
    private func stopTimer() {
        sensorApiTimer?.invalidate()
    }
    
//    @objc func postSensorData() {
//        sensor_healthKit?.fetchHealthData()
////        batteryLogs()
//        startWatchSensors()
//        DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
//            let request = LMSensorManager.shared.fetchSensorDataRequest()
//            SensorLogs.shared.storeSensorRequest(request)
//            printToFile("\n stored file @ \(Date())")
//            print("\n stored file @ \(Date())")
//            BackgroundServices.shared.performTasks()
//        }
//    }
    
    func startWatchSensors() {
        //send a message to watch to collect sensor data
        let messageInfo: [String: Any] = [IOSCommands.sendWatchSensorEvents : true, IOSCommands.timestamp : Date().timeInMilliSeconds]
        WatchSessionManager.shared.updateApplicationContext(applicationContext: (messageInfo))
    }
    
    /// To start sensors observing.
    private func startSensors() {
        
        self.isStarted = true
        
        initiateSensors()
        startAllSensors()
        //If motion sensors are configured, then we can use that. If not we can create new timer to store and post sensor data
        if sensor_motionManager?.CONFIG.sensorTimerDelegate == nil {
            printToFile("not motion sensor configuerd, so starting another timer")
            startTimer()
        }
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    /// To stop sensors observing.
    func stopSensors(_ isLogout: Bool) {
        printToFile("\nStopping senors")
        if isLogout {
            //TODO: clear all log files
        }
        stopTimer()
        stopAllSensors()
        deinitSensors()
    }
    
    func checkIsRunning() {
        if self.isStarted == false {
            if User.shared.isLogin() {
                startSensors()
            }
        }
        BackgroundServices.shared.performTasks()
    }
    // MARK: - SENSOR SETUP METHODS
    
    func setUpSensorMotionManager() {
        sensor_motionManager = MotionManager.init(MotionManager.Config().apply(closure: { (config) in
            config.accelerometerObserver = self
            config.gyroObserver = self
            config.magnetoObserver = self
            config.motionObserver = self
            
            config.sensorTimerDelegate = self
            
            config.sensorTimerDataStoreInterval = 5.0 * 60.0//5 miunutes
        }))
        sensorManager.addSensor(sensor_motionManager!)
    }
    
    func setupBluetoothSensor() {
        sensor_bluetooth = LMBluetoothSensor()
        sensorManager.addSensor(sensor_bluetooth!)
    }
    
    func setupCallsSensor() {
        sensor_calls = CallsSensor.init(CallsSensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
        sensorManager.addSensor(sensor_calls!)
    }
    
    func setupHealthKitSensor() {
        sensor_healthKit = LMHealthKitSensor()
        sensor_healthKit?.observer = self
        sensorManager.addSensor(sensor_healthKit!)
    }
    
    func setupLocationSensor() {
        sensor_location = LocationsSensor.init(LocationsSensor.Config().apply(closure: { config in
            config.sensorObserver = self
            config.minimumInterval = 1.0
        }))
        sensorManager.addSensor(sensor_location!)
    }
    
    func setupPedometerSensor() {
        sensor_pedometer = PedometerSensor.init(PedometerSensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
        sensorManager.addSensor(sensor_pedometer!)
    }
    
    func setupScreenSensor() {
        lampScreenSensor = ScreenSensor.init(ScreenSensor.Config().apply(closure: { config in
            config.sensorObserver = self
            config.interval = 1.0 //in seconds
        }))
        sensorManager.addSensor(lampScreenSensor!)
    }
    
    func setupWifiSensor() {
        sensor_wifi = WiFiSensor.init(WiFiSensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
        sensorManager.addSensor(sensor_wifi!)
    }
}
extension LMSensorManager {
    
    func fetchSensorDataRequest() -> SensorData.Request {
        var arraySensorData = [SensorDataInfo]()
        
        arraySensorData.append(contentsOf: fetchAccelerometerData())
        arraySensorData.append(contentsOf: fetchGyroscopeData())
        arraySensorData.append(contentsOf: fetchMagnetometerData())
        arraySensorData.append(contentsOf: fetchMotionData())

        arraySensorData.append(contentsOf: fetchGPSData())
        arraySensorData.append(contentsOf: fetchCallsData())
        arraySensorData.append(contentsOf: fetchScreenStateData())
        
        if let data = fetchBluetoothData() {
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
        return SensorData.Request(sensorEvents: arraySensorData)
    }
    
    private func fetchAccelerometerData() -> [SensorDataInfo] {
        
        let dataArray = accelerometerDataBufffer
        accelerometerDataBufffer.removeAll(keepingCapacity: true)
        
        let sensorArray = dataArray.map { SensorDataInfo(sensor: SensorType.lamp_accelerometer.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(accelerationRate: $0.acceleration)) }
        return sensorArray
    }
    
    private func fetchGyroscopeData() -> [SensorDataInfo] {
        
        let dataArray = gyroscopeDataBufffer
        gyroscopeDataBufffer.removeAll(keepingCapacity: true)
        
        let sensorArray = dataArray.map { SensorDataInfo(sensor: SensorType.lamp_gyroscope.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(rotationRate: $0.rotationRate)) }
        return sensorArray
    }
    
    private func fetchMagnetometerData() -> [SensorDataInfo] {
        
        let dataArray = magnetometerDataBufffer
        magnetometerDataBufffer.removeAll(keepingCapacity: true)
        
        let sensorArray = dataArray.map { SensorDataInfo(sensor: SensorType.lamp_magnetometer.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(magneticField: $0.magnetoData)) }
        return sensorArray
    }
    
    private func fetchMotionData() -> [SensorDataInfo] {
        
        let dataArray = motionDataBuffer
        motionDataBuffer.removeAll(keepingCapacity: true)
        
        let sensorArray = dataArray.map {
            SensorDataInfo(sensor: SensorType.lamp_accelerometer_motion.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(motionData: $0))
        }
        return sensorArray
    }
    
    private func fetchGPSData() -> [SensorDataInfo] {
        
        let dataArray = locationsDataBuffer
        locationsDataBuffer.removeAll(keepingCapacity: true)

        let sensorArray = dataArray.map { SensorDataInfo(sensor: SensorType.lamp_gps.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(locationData: $0)) }

        return sensorArray
    }
    
    private func fetchCallsData() -> [SensorDataInfo] {
        
        let dataArray = callsDataBuffer
        callsDataBuffer.removeAll(keepingCapacity: true)
        
        let sensorArray = dataArray.map { SensorDataInfo(sensor: SensorType.lamp_calls.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(callsData: $0)) }
        return sensorArray
    }
    
    private func fetchScreenStateData() -> [SensorDataInfo] {
        
        
        let dataArray = screenStateDataBuffer
        screenStateDataBuffer.removeAll(keepingCapacity: true)
        
        let sensorArray = dataArray.map { SensorDataInfo(sensor: SensorType.lamp_screen_state.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(screenData: $0)) }
        return sensorArray
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
        let stpsData = SensorDataInfo(sensor: SensorType.lamp_steps.lampIdentifier, timestamp: Double(data.timestamp), data: stepsModel)
        arrayData.append(stpsData)
        
        var flightModel = SensorDataModel()
        flightModel.value = Double(data.floorsAscended)
        arrayData.append(SensorDataInfo(sensor: SensorType.lamp_flights_up.lampIdentifier, timestamp: Double(data.timestamp), data: flightModel))
        
        var distanceModel = SensorDataModel()
        distanceModel.value = data.distance
        arrayData.append(SensorDataInfo(sensor: SensorType.lamp_distance.lampIdentifier, timestamp: Double(data.timestamp), data: distanceModel))
        
        var descendedModel = SensorDataModel()
        descendedModel.value = Double(data.floorsDescended)
        arrayData.append(SensorDataInfo(sensor: SensorType.lamp_flights_down.lampIdentifier, timestamp: Double(data.timestamp), data: distanceModel))
        
        var currentPaceModel = SensorDataModel()
        currentPaceModel.value = data.currentPace
        arrayData.append(SensorDataInfo(sensor: SensorType.lamp_currentPace.lampIdentifier, timestamp: Double(data.timestamp), data: currentPaceModel))
        
        var currentCadenceModel = SensorDataModel()
        currentCadenceModel.value = data.currentCadence
        arrayData.append(SensorDataInfo(sensor: SensorType.lamp_currentCadence.lampIdentifier, timestamp: Double(data.timestamp), data: currentCadenceModel))
        
        var averageActivePaceModel = SensorDataModel()
        averageActivePaceModel.value = data.averageActivePace
        arrayData.append(SensorDataInfo(sensor: SensorType.lamp_avgActivePace.lampIdentifier, timestamp: Double(data.timestamp), data: averageActivePaceModel))
        
        return arrayData
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
        
        return SensorDataInfo(sensor: SensorType.lamp_bluetooth.lampIdentifier, timestamp: data.timestamp, data: model)
    }
    
    private func fetchWiFiData() -> SensorDataInfo? {
        guard let data = latestWifiData else {
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.wifi_null)
            return nil
        }
        var model = SensorDataModel()
        model.bssid = data.bssid
        model.ssid = data.ssid
        
        return SensorDataInfo(sensor: SensorType.lamp_wifi.lampIdentifier, timestamp: Double(data.timestamp), data: model)
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
        model.workout_duration = data.value
        model.startDate = data.startDate
        model.endDate = data.endDate
        
        return SensorDataInfo(sensor: SensorType.lamp_segment.lampIdentifier, timestamp: Double(data.timestamp), data: model)
    }
}

extension LMSensorManager {
    
//    func sensorDataRequest(with timestamp: Double = Date().timeInMilliSeconds, sensor: SensorType, dataModel: SensorDataModel) -> SensorDataInfo {
//        
//        return SensorDataInfo(sensor: sensor.lampIdentifier, timestamp: timestamp, data: dataModel)
//    }
    
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
            let lampIdentifier = healthData.hkIdentifier.lampIdentifier
            return SensorDataInfo(sensor: lampIdentifier, timestamp: Double(healthData.timestamp), data: data)
        }
        
    }
    
    func fetchHKCategoryData() -> [SensorDataInfo]? {
        
        guard let arrData = sensor_healthKit?.latestCategoryData() else {
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.hkquantity_null)
            return nil
        }
        var arrayData: [SensorDataInfo]?
        guard let categoryTypes: [HKCategoryTypeIdentifier] = sensor_healthKit?.healthCategoryTypes.map( {HKCategoryTypeIdentifier(rawValue: $0.identifier)} ) else { return nil }
        for categoryType in categoryTypes {
            switch categoryType {
            default:
                if let dataArray = allHealthData(for: categoryType, in: arrData) {
                   arrayData = dataArray.map { (categoryData) -> SensorDataInfo in
                        var model = SensorDataModel()
                        model.unit = categoryData.unit
                        model.value = categoryData.value
                        model.valueString = categoryData.valueText
                        model.startDate = categoryData.startDate
                        model.endDate = categoryData.endDate
                        return SensorDataInfo(sensor: categoryType.lampIdentifier, timestamp: Double(categoryData.timestamp), data: model)
                    }
                }
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
                    arrayData.append(SensorDataInfo(sensor: quantityType.lampIdentifier, timestamp: Double(dataDiastolic.timestamp), data: model))
                } else {
                    //let msg = String(format: Logs.Messages.quantityType_null, quantityType.jsonKey)
                    //LMLogsManager.shared.addLogs(level: .warning, logs: msg)
                }
            case .bloodPressureDiastolic:
                ()//handled with Systolic
            default://bodyMass, height, respiratoryRate, heartRate
                if let dataArray = allHealthData(for: quantityType, in: arrData) {
                    let sensorDataArray = dataArray.map { (quantityData) -> SensorDataInfo in
                        var model = SensorDataModel()
                        model.unit = quantityData.unit
                        model.value = quantityData.value
                        model.startDate = quantityData.startDate
                        model.endDate = quantityData.endDate
                        return SensorDataInfo(sensor: quantityType.lampIdentifier, timestamp: Double(quantityData.timestamp), data: model)
                    }
                    arrayData.append(contentsOf: sensorDataArray)
                } else {
                    //let msg = String(format: Logs.Messages.quantityType_null, quantityType.jsonKey)
                    //LMLogsManager.shared.addLogs(level: .warning, logs: msg)
                }
            }
        }
        return arrayData
    }
    
    func latestData(for hkIdentifier: HKCategoryTypeIdentifier, in array: [LMHealthKitCategoryData]) -> LMHealthKitCategoryData? {
        return array.filter({ $0.type == hkIdentifier.rawValue }).max(by: {($0.endDate ?? 0) < ($1.endDate ?? 0) })
    }
    func latestData(for hkIdentifier: HKQuantityTypeIdentifier, in array: [LMHealthKitQuantityData]) -> LMHealthKitQuantityData? {
        return array.filter({ $0.type == hkIdentifier.rawValue }).max(by: {($0.endDate ?? 0) < ($1.endDate ?? 0) })
    }
    
    func allHealthData(for hkIdentifier: HKQuantityTypeIdentifier, in array: [LMHealthKitQuantityData]) -> [LMHealthKitQuantityData]? {
        return array.filter({ $0.type == hkIdentifier.rawValue })
    }
    
    func allHealthData(for hkIdentifier: HKCategoryTypeIdentifier, in array: [LMHealthKitCategoryData]) -> [LMHealthKitCategoryData]? {
        return array.filter({ $0.type == hkIdentifier.rawValue })
    }
    
}

extension LMSensorManager {

    func batteryLogs() {
        guard isBatteryLevelLow() else { return }
        LMLogsManager.shared.addLogs(level: .info, logs: Logs.Messages.battery_low)
    }

    private func isBatteryLevelLow(than level: Float = 20) -> Bool {
        return UIDevice.current.batteryLevel < level/100
    }
}

extension LMSensorManager: iOSDelegate {
    
    func messageReceived(tuple: MessageReceived) {
    }
    
    func applicationContextReceived(tuple: ApplicationContextReceived) {
    }
}
