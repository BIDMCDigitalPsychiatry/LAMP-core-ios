//
//  LMSensorManager.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engineer on 14/01/20.
//

import Foundation
import Sensors
import CoreLocation

#if os(iOS)
import UIKit
import HealthKit
#endif

#if os(watchOS)
import WatchKit
#endif


class LMSensorManager {
    
    //singleton object
    static let shared: LMSensorManager = LMSensorManager()
    let storeSensorDataIntervalInMinutes = 5.0 //minutes
    
    //manager to hold all sensor references
    private let sensorManager = SensorManager()
    var sensor_motionManager: MotionManager?
    var sensor_location: LocationsSensor?
    
    // SensorData storage variables for motion sensors.
    var accelerometerDataBufffer = [AccelerometerData]()
    let queueAccelerometerData = DispatchQueue(label: "thread-safe-AccelerometerData", attributes: .concurrent)
    
    var gyroscopeDataBufffer = [GyroscopeData]()
    let queueGyroscopeData = DispatchQueue(label: "thread-safe-GyroscopeData", attributes: .concurrent)
    
    var magnetometerDataBufffer = [MagnetometerData]()
    let queueMagnetometerData = DispatchQueue(label: "thread-safe-MagnetometerData", attributes: .concurrent)
    
    var motionDataBuffer = [MotionData]()
    let queueMotionData = DispatchQueue(label: "thread-safe-MotionData", attributes: .concurrent)
    
    //check if the sensors are started or not
    private var isStarted = false
    
    //set fetch interval for 5 mins, and to set sync interval as double time of fetch interval
    var isSyncNow = false
    
    //other sensors for iOS
    #if os(iOS)
    var sensor_calls: CallsSensor?
    var lampScreenSensor: ScreenSensor?
    var sensor_wifi: WiFiSensor?
    #endif
    
    var sensor_bluetooth: LMBluetoothSensor?
    var sensor_healthKit: LMHealthKitSensor?
    
    var sensor_pedometer: PedometerSensor?
    
    //TImer to post data to server
    var sensorApiTimer: Timer?
    
    // SensorData storage variables for other sensors
    var locationsDataBuffer = [LocationsData]()
    let queueLocationsData = DispatchQueue(label: "thread-safe-LocationsData", attributes: .concurrent)
    
    var callsDataBuffer = [CallsData]()
    let queueCallsData = DispatchQueue(label: "thread-safe-CallsData", attributes: .concurrent)
    
    var screenStateDataBuffer = [ScreenStateData]()
    let queueScreenStateData = DispatchQueue(label: "thread-safe-ScreenStateData", attributes: .concurrent)
    
    var pedometerDataBuffer = [PedometerData]()
    let queuePedometerData = DispatchQueue(label: "thread-safe-PedometerData", attributes: .concurrent)
    
    var latestWifiData: WiFiScanData?
    
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
        #if os(iOS)
        //sensor_motionManager?.restartMotionUpdates(). this is doing inside the motion sensor class
        sensor_location?.locationManager.stopMonitoringSignificantLocationChanges()
        sensor_location?.locationManager.startMonitoringSignificantLocationChanges()
        #endif
    }
    
    private func initiateSensors() {
        
        setupLocationSensor()
        setUpSensorMotionManager()
        
        #if os(iOS)
        setupCallsSensor()
        setupScreenSensor()

        setupBluetoothSensor()
        setupHealthKitSensor()
        setupPedometerSensor()
        setupWifiSensor()
        #endif
        
    }
    
    private func deinitSensors() {
        
        sensor_motionManager = nil
        sensor_bluetooth = nil
        sensor_healthKit = nil
        sensor_location = nil
        sensor_pedometer = nil
        #if os(iOS)
        sensor_calls = nil
        sensor_wifi = nil
        lampScreenSensor = nil
        #endif
    }
    
    /// To start sensors observing.
    private func startSensors() {
        
        self.isStarted = true
        
        initiateSensors()
        printToFile("\nStarting sensors")
        sensorManager.startAllSensors()

        #if os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        #endif
    }
    
    private func refreshAllSensors() {
        sensorManager.stopAllSensors()
        sensorManager.startAllSensors()
    }
    
    func startWatchSensors() {
        //send a message to watch to collect sensor data
        let messageInfo: [String: Any] = [IOSCommands.sendWatchSensorEvents : true, IOSCommands.timestamp : Date().timeInMilliSeconds]
        WatchSessionManager.shared.updateApplicationContext(applicationContext: (messageInfo))
    }
    
    /// To stop sensors observing.
    func stopSensors() {
        printToFile("\nStopping senors")
        sensorManager.stopAllSensors()
        
        sensor_pedometer?.removeSavedTimestamps()
        sensor_healthKit?.removeSavedTimestamps()
        sensor_healthKit?.clearDataArrays()
        
        deinitSensors()
        
        //clear the bufffers
        accelerometerDataBufffer.removeAll()
        callsDataBuffer.removeAll()
        motionDataBuffer.removeAll()
        pedometerDataBuffer.removeAll()
        locationsDataBuffer.removeAll()
        screenStateDataBuffer.removeAll()
    }
    
    func getSensorDataRequest() -> SensorData.Request {
        
        return SensorData.Request(sensorEvents: getSensorDataArrray())
    }
    
    func checkIsRunning() {
        if self.isStarted == false {
            if User.shared.isLogin() {
                startSensors()
            }
        }
        BackgroundServices.shared.performTasks()
    }
}

// MARK: - SENSOR SETUP METHODS
private extension LMSensorManager {
    
    func setUpSensorMotionManager() {
        sensor_motionManager = MotionManager.init(MotionManager.Config().apply(closure: { (config) in
            config.accelerometerObserver = self
            config.gyroObserver = self
            config.magnetoObserver = self
            config.motionObserver = self
            
            config.sensorTimerDelegate = self
            
            config.sensorTimerDataStoreInterval = storeSensorDataIntervalInMinutes * 60.0
        }))
        sensorManager.addSensor(sensor_motionManager!)
    }
    
    func setupBluetoothSensor() {
        sensor_bluetooth = LMBluetoothSensor()
        sensorManager.addSensor(sensor_bluetooth!)
    }
    
    func setupHealthKitSensor() {
        sensor_healthKit = LMHealthKitSensor()
        sensor_healthKit?.observer = self
        sensorManager.addSensor(sensor_healthKit!)
    }
    
    func setupLocationSensor() {
        sensor_location = LocationsSensor.init(LocationsSensor.Config().apply(closure: { config in
            #if os(iOS)
            config.sensorObserver = self
            config.minimumInterval = 1.0
            config.accuracy = kCLLocationAccuracyBestForNavigation
            #elseif os(watchOS)
            config.accuracy = kCLLocationAccuracyKilometer//TODO: test with other accuracy
            #endif
            
        }))
        sensorManager.addSensor(sensor_location!)
    }
    
    func setupPedometerSensor() {
        sensor_pedometer = PedometerSensor.init(PedometerSensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
        sensorManager.addSensor(sensor_pedometer!)
    }
    #if os(iOS)
    func setupCallsSensor() {
        sensor_calls = CallsSensor.init(CallsSensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
        sensorManager.addSensor(sensor_calls!)
    }
    
    func setupScreenSensor() {
        lampScreenSensor = ScreenSensor.init(ScreenSensor.Config().apply(closure: { config in
            config.sensorObserver = self
            config.interval = 1.0 //in seconds
        }))
        sensorManager.addSensor(lampScreenSensor!)
    }
    
    func setupWifiSensor() {
        //we start scanning only when using the default timer (i.e when calling timeTostore() )
        sensor_wifi = WiFiSensor.init(WiFiSensor.Config().apply(closure: { config in
            config.sensorObserver = self
        }))
        sensorManager.addSensor(sensor_wifi!)
    }
    #endif
}

// MARK: Fetch data as per confoguration
private extension LMSensorManager {
    
    func getSensorDataArrray() -> [SensorDataInfo] {
        var arraySensorData = [SensorDataInfo]()
        
        arraySensorData.append(contentsOf: fetchAccelerometerData())
        arraySensorData.append(contentsOf: fetchGyroscopeData())
        arraySensorData.append(contentsOf: fetchMagnetometerData())
        arraySensorData.append(contentsOf: fetchMotionData())
        
        #if os(iOS)
        arraySensorData.append(contentsOf: fetchGPSData())
        arraySensorData.append(contentsOf: fetchCallsData())
        arraySensorData.append(contentsOf: fetchScreenStateData())
        
        
        if let data = fetchBluetoothData() {
            arraySensorData.append(data)
        }
        
        if let data = fetchWiFiData() {
            arraySensorData.append(data)
        }
        
        if let data = fetchPedometerData() {
            arraySensorData.append(contentsOf: data)
        }
        
        //Health Kit
        if let data = fetchWorkoutSegmentData() {
            arraySensorData.append(data)
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
        sensor_healthKit?.clearDataArrays()//clear all healthkit data fetched
        #endif
        
        return arraySensorData
    }
}

// MARK: Motion sensors data fetch
private extension LMSensorManager {
    
    func fetchAccelerometerData() -> [SensorDataInfo] {
        // read
        var dataArray: [AccelerometerData]!
        queueAccelerometerData.sync {
            // perform read and assign value
            dataArray = accelerometerDataBufffer
        }

        queueAccelerometerData.async(flags: .barrier) {
            self.accelerometerDataBufffer.removeAll(keepingCapacity: true)
        }
        
        let sensorArray = dataArray.map { SensorDataInfo(sensor: SensorType.lamp_accelerometer.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(accelerationRate: $0.acceleration)) }
        return sensorArray
    }
    
    func fetchGyroscopeData() -> [SensorDataInfo] {
        
        // read
        var dataArray: [GyroscopeData]!
        queueGyroscopeData.sync {
            // perform read and assign value
            dataArray = gyroscopeDataBufffer
        }

        queueGyroscopeData.async(flags: .barrier) {
            self.gyroscopeDataBufffer.removeAll(keepingCapacity: true)
        }
        
        let sensorArray = dataArray.map { SensorDataInfo(sensor: SensorType.lamp_gyroscope.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(rotationRate: $0.rotationRate)) }
        return sensorArray
    }
    
    func fetchMagnetometerData() -> [SensorDataInfo] {
        
        // read
        var dataArray: [MagnetometerData]!
        queueMagnetometerData.sync {
            // perform read and assign value
            dataArray = magnetometerDataBufffer
        }

        queueMagnetometerData.async(flags: .barrier) {
            self.magnetometerDataBufffer.removeAll(keepingCapacity: true)
        }
        
        let sensorArray = dataArray.map { SensorDataInfo(sensor: SensorType.lamp_magnetometer.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(magneticField: $0.magnetoData)) }
        return sensorArray
    }
    
    func fetchMotionData() -> [SensorDataInfo] {
        
        // read
        var dataArray: [MotionData]!
        queueMotionData.sync {
            // perform read and assign value
            dataArray = motionDataBuffer
        }

        queueMotionData.async(flags: .barrier) {
            self.motionDataBuffer.removeAll(keepingCapacity: true)
        }
        
        let sensorArray = dataArray.map {
            SensorDataInfo(sensor: SensorType.lamp_accelerometer_motion.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(motionData: $0))
        }
        return sensorArray
    }
}

#if os(iOS)

// MARK: Other sensors data fetch
private extension LMSensorManager {
    
    func fetchGPSData() -> [SensorDataInfo] {
        
        // read
        var dataArray: [LocationsData]!
        queueLocationsData.sync {
            // perform read and assign value
            dataArray = locationsDataBuffer
        }

        queueLocationsData.async(flags: .barrier) {
            self.locationsDataBuffer.removeAll(keepingCapacity: true)
        }
        
        let sensorArray = dataArray.map { SensorDataInfo(sensor: SensorType.lamp_gps.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(locationData: $0)) }
        
        return sensorArray
    }
    
    func fetchCallsData() -> [SensorDataInfo] {
        // read
        var dataArray: [CallsData]!
        queueCallsData.sync {
            // perform read and assign value
            dataArray = callsDataBuffer
        }

        queueCallsData.async(flags: .barrier) {
            self.callsDataBuffer.removeAll(keepingCapacity: true)
        }
        
        let sensorArray = dataArray.map { SensorDataInfo(sensor: SensorType.lamp_calls.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(callsData: $0)) }
        return sensorArray
    }
    
    func fetchScreenStateData() -> [SensorDataInfo] {
        
        // read
        var dataArray: [ScreenStateData]!
        queueScreenStateData.sync {
            // perform read and assign value
            dataArray = screenStateDataBuffer
        }

        queueScreenStateData.async(flags: .barrier) {
            self.screenStateDataBuffer.removeAll(keepingCapacity: true)
        }
        
        let sensorArray = dataArray.map { SensorDataInfo(sensor: SensorType.lamp_screen_state.lampIdentifier, timestamp: $0.timestamp, data: SensorDataModel(screenData: $0)) }
        return sensorArray
    }
    
    func fetchPedometerData() -> [SensorDataInfo]? {
        
        var arrayData = [SensorDataInfo]()
        
        // read
        var dataArray: [PedometerData]!
        queuePedometerData.sync {
            // perform read and assign value
            dataArray = pedometerDataBuffer
        }
        queuePedometerData.async(flags: .barrier) {
            self.pedometerDataBuffer.removeAll(keepingCapacity: true)
        }
        
        for data in dataArray {
            
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
        }

        return arrayData
    }
    
    func fetchBluetoothData() -> SensorDataInfo? {
        guard let data = sensor_bluetooth?.latestData() else {
            return nil
        }
        var model = SensorDataModel()
        model.bt_address = data.address
        model.bt_name = data.name
        model.bt_rssi = data.rssi
        
        return SensorDataInfo(sensor: SensorType.lamp_bluetooth.lampIdentifier, timestamp: data.timestamp, data: model)
    }
    
    func fetchWiFiData() -> SensorDataInfo? {
        guard let data = latestWifiData else {
            return nil
        }
        var model = SensorDataModel()
        model.bssid = data.bssid
        model.ssid = data.ssid
        
        //clear existing
        latestWifiData = nil
        
        return SensorDataInfo(sensor: SensorType.lamp_wifi.lampIdentifier, timestamp: Double(data.timestamp), data: model)
    }
    
    func fetchWorkoutSegmentData() -> SensorDataInfo? {
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

// MARK: HealthKit data
private extension LMSensorManager {
    
    func fetchHKCharacteristicData() -> [SensorDataInfo]? {
        
        guard let arrData = sensor_healthKit?.latestCharacteristicData() else {
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

// MARK: Battery Logs
extension LMSensorManager {
    
    public func batteryLogs() {
        guard isBatteryLevelLow() else { return }
        //LMLogsManager.shared.addLogs(level: .info, logs: Logs.Messages.battery_low)
    }
    
    private func isBatteryLevelLow(than level: Float = 20) -> Bool {
        return UIDevice.current.batteryLevel < level/100
    }
}

#endif
