//
//  LMSensorManager.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engineer on 14/01/20.
//

import Foundation
import LAMP
import CoreLocation

#if os(iOS)
import UIKit
import HealthKit
#endif

#if os(watchOS)
import WatchKit
#endif


class LMSensorManager {
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeStyle = DateFormatter.Style.medium
        formatter.dateStyle = DateFormatter.Style.medium
        return formatter
    }()
    //singleton object
    static let shared: LMSensorManager = LMSensorManager()
    let storeSensorDataIntervalInMinutes = 5.0 //minutes
    
    //manager to hold all sensor references
    private let sensorManager = SensorManager()
    var sensor_motionManager: MotionManager?
    var sensor_location: LocationsSensor?
    //only used in iOS now
    var sensor_Activity: ActivitySensor?
    
    
    // SensorData storage variables for motion sensors.
    var accelerometerDataBufffer = [AccelerometerData]()
    let queueAccelerometerData = DispatchQueue(label: "thread-safe-AccelerometerData", attributes: .concurrent)
    
    var gyroscopeDataBufffer = [GyroscopeData]()
    let queueGyroscopeData = DispatchQueue(label: "thread-safe-GyroscopeData", attributes: .concurrent)
    
    var magnetometerDataBufffer = [MagnetometerData]()
    let queueMagnetometerData = DispatchQueue(label: "thread-safe-MagnetometerData", attributes: .concurrent)
    
    var motionDataBuffer = [MotionData]()
    let queueMotionData = DispatchQueue(label: "thread-safe-MotionData", attributes: .concurrent)
    
    var activityDataBuffer = [ActivityData]()
    let queueActivityData = DispatchQueue(label: "thread-safe-ActivityData", attributes: .concurrent)
    
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
        printToFile("appDidEnterBackground")
        //sensor_motionManager?.restartMotionUpdates(). this is doing inside the motion sensor class
        sensor_location?.locationManager.stopMonitoringSignificantLocationChanges()
        sensor_location?.locationManager.startMonitoringSignificantLocationChanges()
        #endif
    }
    
    private func initiateSensors() {
        
        setupLocationSensor()
        setUpSensorMotionManager()
        
        #if os(iOS)
        setupActivitySensor()
        
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
        
        sensor_Activity = nil
        sensor_pedometer = nil
        #if os(iOS)
        sensor_calls = nil
        sensor_wifi = nil
        lampScreenSensor = nil
        #endif
    }
    
    /// To start sensors observing.
    private func startSensors() {

        initiateSensors()
        printToFile("\nStarting sensors")
        sensorManager.startAllSensors()
    }
    
    private func refreshAllSensors() {
        sensorManager.stopAllSensors()
        sensorManager.startAllSensors()
    }
    
    func startWatchSensors() {
        #if os(iOS)
        //send a message to watch to collect sensor data
        let messageInfo: [String: Any] = [IOSCommands.sendWatchSensorEvents : true, IOSCommands.timestamp : Date().timeInMilliSeconds]
        WatchSessionManager.shared.updateApplicationContext(applicationContext: (messageInfo))
        #endif
    }
    
    /// To stop sensors observing.
    func stopSensors() {
        
        printToFile("\nStopping senors")
        isStarted = false
        self.sensorApiTimer?.invalidate()
        self.sensorApiTimer = nil
        
        sensorManager.stopAllSensors()
        
        sensor_pedometer?.removeSavedTimestamps()
        sensor_healthKit?.removeSavedTimestamps()
        sensor_healthKit?.clearDataArrays()
        
        deinitSensors()
        
        //clear the bufffers
        activityDataBuffer.removeAll()
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
    
    func runevery(seconds: Double, closure: @escaping () -> ()) {
        
//        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).asyncAfter(deadline: .now() + seconds) {
//            closure()
//            self.runevery(seconds: seconds, closure: closure)
//        }
    }
    
    func runevery(seconds: Double) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            self.sensorApiTimer?.invalidate()
            self.sensorApiTimer = nil
            
            self.sensorApiTimer = Timer.scheduledTimer(timeInterval: seconds, target: self, selector: #selector(self.timeToStore), userInfo: nil, repeats: true)
            RunLoop.current.add(self.sensorApiTimer!, forMode: .common)
            RunLoop.current.run()
        }
        
    }
    
    func checkIsRunning() {
        guard User.shared.isLogin() else {
            printToFile("\nNot logined")
            return }
        if self.isStarted == false {
            self.isStarted = true
            startSensors()

            runevery(seconds: storeSensorDataIntervalInMinutes * 60)
        }
        BackgroundServices.shared.performTasks()
    }
    
    func showLocationAlert() {
        #if os(iOS)
        let alertController = UIAlertController(title: "Location Permission Required", message: "Please enable location permissions in settings.", preferredStyle: .alert)
        
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

// MARK: - SENSOR SETUP METHODS
private extension LMSensorManager {
    
    func setUpSensorMotionManager() {
        sensor_motionManager = MotionManager.init(MotionManager.Config().apply(closure: { (config) in
            config.accelerometerObserver = self
            config.gyroObserver = self
            config.magnetoObserver = self
            config.motionObserver = self
            
            config.sensorTimerDelegate = self
            
            //config.sensorTimerDataStoreInterval = storeSensorDataIntervalInMinutes * 60.0
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
    
    func setupActivitySensor() {
        sensor_Activity = ActivitySensor()
        sensor_Activity?.sensorObserver = self
        sensorManager.addSensor(sensor_Activity!)
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
    
    func getSensorDataArrray() -> [SensorEvent<SensorDataModel>] {
        var arraySensorData = [SensorEvent<SensorDataModel>]()
        
        arraySensorData.append(contentsOf: fetchAccelerometerData())
        arraySensorData.append(contentsOf: fetchGyroscopeData())
        arraySensorData.append(contentsOf: fetchMagnetometerData())
        arraySensorData.append(contentsOf: fetchMotionData())
        
        #if os(iOS)
        arraySensorData.append(contentsOf: fetchActivityData())
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
    
    func fetchAccelerometerData() -> [SensorEvent<SensorDataModel>] {
        // read
        var dataArray: [AccelerometerData]!
        queueAccelerometerData.sync {
            // perform read and assign value
            dataArray = accelerometerDataBufffer
        }
        printToFile("accelerometer count \(dataArray.count)")
        queueAccelerometerData.async(flags: .barrier) {
            self.accelerometerDataBufffer.removeAll(keepingCapacity: true)
        }
        
        let sensorArray = dataArray.map { SensorEvent(timestamp: $0.timestamp, sensor: SensorType.lamp_accelerometer.lampIdentifier, data: SensorDataModel(accelerationRate: $0.acceleration)) }
        return sensorArray
    }
    
    func fetchGyroscopeData() -> [SensorEvent<SensorDataModel>] {
        
        // read
        var dataArray: [GyroscopeData]!
        queueGyroscopeData.sync {
            // perform read and assign value
            dataArray = gyroscopeDataBufffer
        }
        
        queueGyroscopeData.async(flags: .barrier) {
            self.gyroscopeDataBufffer.removeAll(keepingCapacity: true)
        }
        
        let sensorArray = dataArray.map { SensorEvent(timestamp: $0.timestamp, sensor: SensorType.lamp_gyroscope.lampIdentifier, data: SensorDataModel(rotationRate: $0.rotationRate)) }
        return sensorArray
    }
    
    func fetchMagnetometerData() -> [SensorEvent<SensorDataModel>] {
        
        // read
        var dataArray: [MagnetometerData]!
        queueMagnetometerData.sync {
            // perform read and assign value
            dataArray = magnetometerDataBufffer
        }
        
        queueMagnetometerData.async(flags: .barrier) {
            self.magnetometerDataBufffer.removeAll(keepingCapacity: true)
        }
        
        let sensorArray = dataArray.map { SensorEvent(timestamp: $0.timestamp, sensor: SensorType.lamp_magnetometer.lampIdentifier, data: SensorDataModel(magneticField: $0.magnetoData)) }
        return sensorArray
    }
    
    func fetchMotionData() -> [SensorEvent<SensorDataModel>] {
        
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
            SensorEvent(timestamp: $0.timestamp, sensor: SensorType.lamp_accelerometer_motion.lampIdentifier, data: SensorDataModel(motionData: $0))
        }
        return sensorArray
    }
}

#if os(iOS)
// MARK: Other sensors data fetch
private extension LMSensorManager {
    
    func fetchActivityData() -> [SensorEvent<SensorDataModel>] {
        
        // read
        var dataArray: [ActivityData]!
        queueGyroscopeData.sync {
            // perform read and assign value
            dataArray = activityDataBuffer
        }
        
        queueActivityData.async(flags: .barrier) {
            self.activityDataBuffer.removeAll(keepingCapacity: true)
        }
        
        let sensorArray = dataArray.map { SensorEvent(timestamp: $0.timestamp, sensor: SensorType.lamp_Activity.lampIdentifier, data: SensorDataModel(activityData: $0.activity)) }
        return sensorArray
    }
    
    func fetchGPSData() -> [SensorEvent<SensorDataModel>] {
        
        // read
        var dataArray: [LocationsData]!
        queueLocationsData.sync {
            // perform read and assign value
            dataArray = locationsDataBuffer
        }
        
        queueLocationsData.async(flags: .barrier) {
            self.locationsDataBuffer.removeAll(keepingCapacity: true)
        }
        
        let sensorArray = dataArray.map { SensorEvent(timestamp: $0.timestamp, sensor: SensorType.lamp_gps.lampIdentifier, data: SensorDataModel(locationData: $0)) }
        
        return sensorArray
    }
    
    func fetchCallsData() -> [SensorEvent<SensorDataModel>] {
        // read
        var dataArray: [CallsData]!
        queueCallsData.sync {
            // perform read and assign value
            dataArray = callsDataBuffer
        }
        
        queueCallsData.async(flags: .barrier) {
            self.callsDataBuffer.removeAll(keepingCapacity: true)
        }
        
        let sensorArray = dataArray.map { SensorEvent(timestamp: $0.timestamp, sensor: SensorType.lamp_calls.lampIdentifier, data: SensorDataModel(callsData: $0)) }
        return sensorArray
    }
    
    func fetchScreenStateData() -> [SensorEvent<SensorDataModel>] {
        
        // read
        var dataArray: [ScreenStateData]!
        queueScreenStateData.sync {
            // perform read and assign value
            dataArray = screenStateDataBuffer
        }
        
        queueScreenStateData.async(flags: .barrier) {
            self.screenStateDataBuffer.removeAll(keepingCapacity: true)
        }
        
        let sensorArray = dataArray.map { SensorEvent(timestamp: $0.timestamp, sensor: SensorType.lamp_screen_state.lampIdentifier, data: SensorDataModel(screenData: $0)) }
        return sensorArray
    }
    
    func fetchPedometerData() -> [SensorEvent<SensorDataModel>]? {
        
        var arrayData = [SensorEvent<SensorDataModel>]()
        
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
            let stpsData = SensorEvent(timestamp: Double(data.timestamp), sensor: SensorType.lamp_steps.lampIdentifier, data: stepsModel)
            arrayData.append(stpsData)
            
            var flightModel = SensorDataModel()
            flightModel.value = Double(data.floorsAscended)
            arrayData.append(SensorEvent(timestamp: Double(data.timestamp), sensor: SensorType.lamp_flights_up.lampIdentifier, data: flightModel))
            
            var distanceModel = SensorDataModel()
            distanceModel.value = data.distance
            arrayData.append(SensorEvent(timestamp: Double(data.timestamp), sensor: SensorType.lamp_distance.lampIdentifier, data: distanceModel))
            
            var descendedModel = SensorDataModel()
            descendedModel.value = Double(data.floorsDescended)
            arrayData.append(SensorEvent(timestamp: Double(data.timestamp),sensor: SensorType.lamp_flights_down.lampIdentifier, data: distanceModel))
            
            var currentPaceModel = SensorDataModel()
            currentPaceModel.value = data.currentPace
            arrayData.append(SensorEvent(timestamp: Double(data.timestamp), sensor: SensorType.lamp_currentPace.lampIdentifier, data: currentPaceModel))
            
            var currentCadenceModel = SensorDataModel()
            currentCadenceModel.value = data.currentCadence
            arrayData.append(SensorEvent(timestamp: Double(data.timestamp), sensor: SensorType.lamp_currentCadence.lampIdentifier, data: currentCadenceModel))
            
            var averageActivePaceModel = SensorDataModel()
            averageActivePaceModel.value = data.averageActivePace
            arrayData.append(SensorEvent(timestamp: Double(data.timestamp), sensor: SensorType.lamp_avgActivePace.lampIdentifier, data: averageActivePaceModel))
        }
        
        return arrayData
    }
    
    func fetchBluetoothData() -> SensorEvent<SensorDataModel>? {
        guard let data = sensor_bluetooth?.latestData() else {
            return nil
        }
        var model = SensorDataModel()
        model.bt_address = data.address
        model.bt_name = data.name
        model.bt_rssi = data.rssi
        
        return SensorEvent(timestamp: data.timestamp, sensor: SensorType.lamp_bluetooth.lampIdentifier, data: model)
    }
    
    func fetchWiFiData() -> SensorEvent<SensorDataModel>? {
        guard let data = latestWifiData else {
            return nil
        }
        var model = SensorDataModel()
        model.bssid = data.bssid
        model.ssid = data.ssid
        
        //clear existing
        latestWifiData = nil
        
        return SensorEvent(timestamp: Double(data.timestamp), sensor: SensorType.lamp_wifi.lampIdentifier, data: model)
    }
    
    func fetchWorkoutSegmentData() -> SensorEvent<SensorDataModel>? {
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
        
        return SensorEvent(timestamp: Double(data.timestamp), sensor: SensorType.lamp_segment.lampIdentifier, data: model)
    }
}

// MARK: HealthKit data
private extension LMSensorManager {
    
    func fetchHKCharacteristicData() -> [SensorEvent<SensorDataModel>]? {
        
        guard let arrData = sensor_healthKit?.latestCharacteristicData() else {
            return nil
        }
        
        return arrData.map { (healthData) -> SensorEvent<SensorDataModel> in
            var data = SensorDataModel()
            data.value = healthData.value
            data.valueString = healthData.valueText
            data.startDate = healthData.startDate
            data.endDate = healthData.endDate
            let lampIdentifier = healthData.hkIdentifier.lampIdentifier
            return SensorEvent(timestamp: Double(healthData.timestamp), sensor: lampIdentifier, data: data)
        }
        
    }
    
    func fetchHKCategoryData() -> [SensorEvent<SensorDataModel>]? {
        
        guard let arrData = sensor_healthKit?.latestCategoryData() else {
            return nil
        }
        var arrayData: [SensorEvent<SensorDataModel>]?
        guard let categoryTypes: [HKCategoryTypeIdentifier] = sensor_healthKit?.healthCategoryTypes.map( {HKCategoryTypeIdentifier(rawValue: $0.identifier)} ) else { return nil }
        for categoryType in categoryTypes {
            switch categoryType {
            default:
                if let dataArray = allHealthData(for: categoryType, in: arrData) {
                    arrayData = dataArray.map { (categoryData) -> SensorEvent<SensorDataModel> in
                        var model = SensorDataModel()
                        model.unit = categoryData.unit
                        model.value = categoryData.value
                        model.valueString = categoryData.valueText
                        model.startDate = categoryData.startDate
                        model.endDate = categoryData.endDate
                        return SensorEvent(timestamp: Double(categoryData.timestamp), sensor: categoryType.lampIdentifier, data: model)
                    }
                }
            }
        }
        return arrayData
    }
    
    func fetchHealthKitQuantityData() -> [SensorEvent<SensorDataModel>]? {
        guard let arrData = sensor_healthKit?.latestQuantityData() else {
            return nil
        }
        var arrayData = [SensorEvent<SensorDataModel>]()
        
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
                    arrayData.append(SensorEvent(timestamp: Double(dataDiastolic.timestamp), sensor: quantityType.lampIdentifier, data: model))
                }
            case .bloodPressureDiastolic:
                ()//handled with Systolic
            default://bodyMass, height, respiratoryRate, heartRate
                if let dataArray = allHealthData(for: quantityType, in: arrData) {
                    let sensorDataArray = dataArray.map { (quantityData) -> SensorEvent<SensorDataModel> in
                        var model = SensorDataModel()
                        model.unit = quantityData.unit
                        model.value = quantityData.value
                        model.startDate = quantityData.startDate
                        model.endDate = quantityData.endDate
                        model.source = quantityData.source //for step count only
                        return SensorEvent(timestamp: Double(quantityData.timestamp), sensor: quantityType.lampIdentifier, data: model)
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
#endif
