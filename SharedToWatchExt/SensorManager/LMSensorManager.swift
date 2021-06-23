//
//  LMSensorManager.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engineer on 14/01/20.
//

import Foundation
import LAMP
import CoreLocation
//import Combine

#if os(iOS)
import UIKit
import HealthKit
#endif

#if os(watchOS)
import WatchKit
#endif

class LMSensorManager {
    
    // to store frequency of gps, accelerometer and device_motion
    var frquencySettings = [String: Double]()
    var isUploadUsingAnyNetwork: Bool = true
    var isReachableViaWiFi: Bool = true
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeStyle = DateFormatter.Style.medium
        formatter.dateStyle = DateFormatter.Style.medium
        return formatter
    }()
    //singleton object
    static let shared: LMSensorManager = LMSensorManager()
    let storeSensorDataIntervalInMinutes = 5.0// minutes
    
    //manager to hold all sensor references
    private let sensorManager = SensorManager()
    var sensor_motionManager: MotionManager?
    var sensor_location: LocationsSensor?
    //only used in iOS now
    var sensor_Activity: ActivitySensor?
    
    
    // SensorData storage variables for motion sensors.
    var accelerometerDataBufffer = [AccelerometerData]()
    let queueAccelerometerData = DispatchQueue(label: "thread-safe-AccelerometerData", attributes: .concurrent)
    
//    var gyroscopeDataBufffer = [GyroscopeData]()
//    let queueGyroscopeData = DispatchQueue(label: "thread-safe-GyroscopeData", attributes: .concurrent)
//
//    var magnetometerDataBufffer = [MagnetometerData]()
//    let queueMagnetometerData = DispatchQueue(label: "thread-safe-MagnetometerData", attributes: .concurrent)
    
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
    
    #if os(iOS)
    var reachability: Reachability = try! Reachability()
    #endif
    
    var sensor_bluetooth: LMBluetoothSensor?
    var sensor_healthKit: LMHealthKitSensor?
    var sensor_pedometer: PedometerSensor?
    
    //Timer to post data to server
    //var sensorApiTimer: Timer?
    var sensorAPITimer: RepeatingTimer?
    
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
    
    //******define all sensor specs here.**********
    lazy var allSensorSpecs: [String] = {
       var sensors = [SensorType.lamp_gps.lampIdentifier,
                      SensorType.lamp_Activity.lampIdentifier,
                      SensorType.lamp_telephony.lampIdentifier,
                      SensorType.lamp_screen_state.lampIdentifier,
                      SensorType.lamp_nearby_device.lampIdentifier,
                      SensorType.lamp_steps.lampIdentifier,
                      SensorType.lamp_device_motion.lampIdentifier,
                      SensorType.lamp_accelerometer.lampIdentifier,
                      SensorType.lamp_analytics.lampIdentifier]
        sensors.append(contentsOf: LMHealthKitSensor.healthkitSensors)
        print("sensors = \(sensors)")
        return sensors
    }()
    
    private init() {
        
        #if os(iOS)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        
        // Reachability
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
        #endif
    }
    
    deinit {
        #if os(iOS)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didEnterBackgroundNotification,
                                                  object: nil)
        
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
        #endif
    }
    
    @objc private func appDidEnterBackground() {
        #if os(iOS)
        printToFile("appDidEnterBackground")
        sensor_location?.locationManager.stopMonitoringSignificantLocationChanges()
        sensor_location?.locationManager.startMonitoringSignificantLocationChanges()
        #endif
    }
    
    @objc func reachabilityChanged(note: Notification) {
        #if os(iOS)
        guard let reachability = note.object as? Reachability else { return }

        switch reachability.connection {
        case .wifi:
            isReachableViaWiFi = true
            print("Reachable via WiFi")
        case .cellular:
            isReachableViaWiFi = false
            print("Reachable via Cellular")
        case .unavailable:
            isReachableViaWiFi = false
            print("Network not reachable")
        }
        #endif
    }
    
    private func initiateSensors() {
        
        //Always setup location sensors to keep the app alive in background. but collect location data only if its configured.
        print("sensorIdentifiers = \(sensorIdentifiers)")
        setupLocationSensor(isNeedData: sensorIdentifiers.contains(SensorType.lamp_gps.lampIdentifier))
        
        let isExist = setUpSensorMotionManager(sensorIdentifiers)
        
        if isExist {
            // then we are using the timer of motion to store/sync sensor data to server
        } else {
            runevery(seconds: storeSensorDataIntervalInMinutes * 60)
        }
        
        #if os(iOS)
        
        if sensorIdentifiers.contains(SensorType.lamp_Activity.lampIdentifier) {
            setupActivitySensor()
        }
        if sensorIdentifiers.contains(SensorType.lamp_telephony.lampIdentifier) {
            setupCallsSensor()
        }
        if sensorIdentifiers.contains(SensorType.lamp_screen_state.lampIdentifier) {
            UIDevice.current.isBatteryMonitoringEnabled = true
            setupScreenSensor()
        }
        if sensorIdentifiers.contains(SensorType.lamp_nearby_device.lampIdentifier) {
            setupWifiSensor()
            setupBluetoothSensor()
        }
        
        setupHealthKitSensor(sensorIdentifiers)
        
        if sensorIdentifiers.contains(SensorType.lamp_steps.lampIdentifier) {
            setupPedometerSensor()
        }
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
    
    //var subscriber: AnyCancellable?
    var sensorIdentifiers: [String] = []
    /// To start sensors observing.
    private func startSensors() {
        
        guard let participantId = User.shared.userId else { return }
        let lampAPI = NetworkConfig.networkingAPI()
        let endPoint =  String(format: Endpoint.sensor.rawValue, participantId)
        let requestData = RequestData(endpoint: endPoint, requestTye: .get)
        lampAPI.makeWebserviceCall(with: requestData) { (response: Result<SensorAPI.Response>) in
            switch response {
            case .failure(let err):
                if let nsError = err as NSError? {
                    let errorCode = nsError.code
                    /// -1009 is the offline error code
                    /// so log errors other than connection issue
                    if errorCode == -1009 {
                        LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.network_error + " " + nsError.localizedDescription)
                    } else {
                        LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + nsError.localizedDescription)
                    }
                }
            case .success(let response):
                let sensorSpecs: [Sensor] = response.data
                print("sensorSpecs count = \(sensorSpecs.count)")
                SensorLogs.shared.storeSensorSpecs(specs: sensorSpecs)
            }
            //load sensorspec after api call.
            DispatchQueue.main.async {
                self.loadSensorSpecs()
            }
        }
        
        
        /*var sensorSpecs: [Sensor] = []
        guard let authheader = Endpoint.getSessionKey(), let participantId = User.shared.userId else {
            printError("Auth header missing")
            return
        }
        OpenAPIClientAPI.basePath = LampURL.baseURLString
        OpenAPIClientAPI.customHeaders = ["Authorization": "Basic \(authheader)", "Content-Type": "application/json"]
        let publisher = SensorAPI.sensorAllByParticipant(participantId: participantId)
        
        subscriber = publisher.sink(receiveCompletion: { [weak self] value in
            guard let self = self else { return }
            print("value3 = \(value)")
            switch value {
            case .failure(let ErrorResponse.error(code, data, error)):
                printError("sensor names error code\(code), \(error.localizedDescription)")
                if let data = data {
                    let decoder = JSONDecoder()
                    do {
                        let errResponse = try decoder.decode(ErrResponse.self, from: data)
                        printError("\nerrResponse \(String(describing: errResponse.error))")
                    } catch let err {
                        printError("err = \(err.localizedDescription)")
                    }
                }
            case .failure(let error):
                printError("postSensorData error \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    let errorCode = nsError.code
                    /// -1009 is the offline error code
                    /// so log errors other than connection issue
                    if errorCode == -1009 {
                        LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.network_error + " " + nsError.localizedDescription)
                    } else {
                        LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + nsError.localizedDescription)
                    }
                }
            case .finished:
                SensorLogs.shared.storeSensorSpecs(specs: sensorSpecs)
            }
            //load sensorspec after api call.
            self.loadSensorSpecs()
            
        }, receiveValue: { response in
            sensorSpecs.append(contentsOf: response.data)
        })
        */
    }

    private func loadSensorSpecs() {
        sensorIdentifiers.removeAll()
        if let specsDownloaded = SensorLogs.shared.fetchSensorSpecs(), specsDownloaded.count > 0 {
            sensorIdentifiers = specsDownloaded.compactMap({ $0.spec })
            //celllular upload check
            self.isUploadUsingAnyNetwork = specsDownloaded.contains { (sensor) -> Bool in
                return sensor.settings?.cellular_upload == true
            }
            // filter null calues
            let cellularFlags: [Bool] = specsDownloaded.compactMap({$0.settings?.cellular_upload})
            // if atleast one key is exist and it contains true then we can use any network.
            if cellularFlags.count > 0 {
                self.isUploadUsingAnyNetwork = cellularFlags.contains(true)
            }
            
            //load settings dict for frquency
            specsDownloaded.forEach { (sensor) in
                if let spec = sensor.spec, let settings = sensor.settings, let frquency = settings.frequency {
                    frquencySettings[spec] = frquency
                }
            }
            
        } else {
            sensorIdentifiers = allSensorSpecs
            frquencySettings = [:]
        }
        self.initiateSensors()
        self.sensorManager.startAllSensors()
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
        sensorAPITimer = nil
        
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
//        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
//            self.sensorApiTimer?.invalidate()
//            self.sensorApiTimer = nil
//
//            self.sensorApiTimer = Timer.scheduledTimer(timeInterval: seconds, target: self, selector: #selector(self.timeToStore), userInfo: nil, repeats: true)
//            RunLoop.current.add(self.sensorApiTimer!, forMode: .common)
//            RunLoop.current.run()
//        }
        
        sensorAPITimer = RepeatingTimer(timeInterval: storeSensorDataIntervalInMinutes * 60)
        sensorAPITimer?.eventHandler = {
            self.timeToStore()
        }
        sensorAPITimer?.resume()
    }
    
    func checkIsRunning() {
        guard User.shared.isLogin() else {
            printToFile("\nNot logined")
            return }
        if self.isStarted == false {
            self.isStarted = true
            startSensors()

            //runevery(seconds: storeSensorDataIntervalInMinutes * 60)
        }
        if isOktoSync() {
            //check battery state
            guard BatteryState.shared.isLowPowerEnabled == false else {
                printToFile("isLowPowerEnabled")
                return }
            BackgroundServices.shared.performTasks()
        }
    }
    
    func isOktoSync() -> Bool {
        //if use Wifi only, and if reachability with Cellular then return
        if isUploadUsingAnyNetwork == false && isReachableViaWiFi == false { // it means we should sync data only with WiFi,
            return false
        }
        return true
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
    
    func setUpSensorMotionManager(_ specIdentifiers: [String]) -> Bool {
        
        let isDevicemotion = specIdentifiers.contains(SensorType.lamp_device_motion.lampIdentifier)
        let isAccelerometer = specIdentifiers.contains(SensorType.lamp_accelerometer.lampIdentifier)
        if isDevicemotion || isAccelerometer {
            
            sensor_motionManager = MotionManager.init(MotionManager.Config().apply(closure: { (config) in
                if isAccelerometer {
                    config.accelerometerObserver = self
                }
                //config.gyroObserver = self
                //config.magnetoObserver = self
                if isDevicemotion {
                    config.motionObserver = self
                }
                config.sensorTimerDelegate = self
                config.sensorTimerDataStoreInterval = storeSensorDataIntervalInMinutes * 60.0
                
                //set frquency
                if isAccelerometer && isDevicemotion {
                    if let frquency = frquencySettings[SensorType.lamp_device_motion.lampIdentifier] {
                        config.frequency = frquency
                    }
                    if let frquency = frquencySettings[SensorType.lamp_accelerometer.lampIdentifier], let frequecySet = config.frequency,  frquency > frequecySet {
                        config.frequency = frquency
                    }
                } else if isDevicemotion {
                    if let frquency = frquencySettings[SensorType.lamp_device_motion.lampIdentifier] {
                        config.frequency = frquency
                    }
                } else { //accelero only
                    if let frquency = frquencySettings[SensorType.lamp_accelerometer.lampIdentifier] {
                        config.frequency = frquency
                    }
                }
            }))
            sensorManager.addSensor(sensor_motionManager!)
            return true
        }
        return false
    }
    
    func setupBluetoothSensor() {
        sensor_bluetooth = LMBluetoothSensor()
        sensorManager.addSensor(sensor_bluetooth!)
    }
    
    func setupHealthKitSensor(_ specIdentifiers: [String]) {
        #if os(iOS)
        let hkSensors = LMHealthKitSensor.healthkitSensors
        if specIdentifiers.contains(where: { (element) -> Bool in
            return hkSensors.contains(element)
        }) {
            sensor_healthKit = LMHealthKitSensor(specIdentifiers)
            sensor_healthKit?.observer = self
            sensorManager.addSensor(sensor_healthKit!)
        }
        #endif
    }
    
    func setupLocationSensor(isNeedData: Bool) {
      sensor_location = LocationsSensor.init(LocationsSensor.Config().apply(closure: { config in
            #if os(iOS)
            config.sensorObserver = self
            if isNeedData {
                config.locationDataObserver = self
            }
            config.accuracy = kCLLocationAccuracyBestForNavigation
            if let frquency = frquencySettings[SensorType.lamp_gps.lampIdentifier] {
                config.frequency = frquency
            }
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
//        arraySensorData.append(contentsOf: fetchGyroscopeData())
//        arraySensorData.append(contentsOf: fetchMagnetometerData())
        arraySensorData.append(contentsOf: fetchMotionData())
        
        #if os(iOS)
        arraySensorData.append(contentsOf: fetchActivityData())
        arraySensorData.append(contentsOf: fetchGPSData())
        arraySensorData.append(contentsOf: fetchCallsData())
        arraySensorData.append(contentsOf: fetchScreenStateData())
        
        arraySensorData.append(contentsOf: fetchNearbyDeviceData())

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
    
//    func fetchGyroscopeData() -> [SensorEvent<SensorDataModel>] {
//
//        // read
//        var dataArray: [GyroscopeData]!
//        queueGyroscopeData.sync {
//            // perform read and assign value
//            dataArray = gyroscopeDataBufffer
//        }
//
//        queueGyroscopeData.async(flags: .barrier) {
//            self.gyroscopeDataBufffer.removeAll(keepingCapacity: true)
//        }
//
//        let sensorArray = dataArray.map { SensorEvent(timestamp: $0.timestamp, sensor: SensorType.lamp_gyroscope.lampIdentifier, data: SensorDataModel(rotationRate: $0.rotationRate)) }
//        return sensorArray
//    }
    
//    func fetchMagnetometerData() -> [SensorEvent<SensorDataModel>] {
//
//        // read
//        var dataArray: [MagnetometerData]!
//        queueMagnetometerData.sync {
//            // perform read and assign value
//            dataArray = magnetometerDataBufffer
//        }
//
//        queueMagnetometerData.async(flags: .barrier) {
//            self.magnetometerDataBufffer.removeAll(keepingCapacity: true)
//        }
//
//        let sensorArray = dataArray.map { SensorEvent(timestamp: $0.timestamp, sensor: SensorType.lamp_magnetometer.lampIdentifier, data: SensorDataModel(magneticField: $0.magnetoData)) }
//        return sensorArray
//    }
    
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
            SensorEvent(timestamp: $0.timestamp, sensor: SensorType.lamp_device_motion.lampIdentifier, data: SensorDataModel(motionData: $0))
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
        queueActivityData.sync {
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
        print("fetch gps")
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
        
        let sensorArray = dataArray.map { SensorEvent(timestamp: $0.timestamp, sensor: SensorType.lamp_telephony.lampIdentifier, data: SensorDataModel(callsData: $0)) }
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
        // read
        var dataArray: [PedometerData]!
        queuePedometerData.sync {
            // perform read and assign value
            dataArray = pedometerDataBuffer
        }
        queuePedometerData.async(flags: .barrier) {
            self.pedometerDataBuffer.removeAll(keepingCapacity: true)
        }
        
        let sensorArray = dataArray.map { SensorEvent(timestamp: $0.timestamp, sensor: SensorType.lamp_steps.lampIdentifier, data: SensorDataModel(pedometerData: $0)) }
        return sensorArray
    }
    
    func fetchNearbyDeviceData() -> [SensorEvent<SensorDataModel>] {
        var dataArray: [SensorEvent<SensorDataModel>] = []
        if let data = sensor_bluetooth?.latestData() {
            var model = SensorDataModel()
            model.type = SensorType.NearbyDevicetype.bluetooth
            model.address = data.address
            model.name = data.name
            model.strength = data.rssi
            let bluetoothevent = SensorEvent(timestamp: data.timestamp, sensor: SensorType.lamp_nearby_device.lampIdentifier, data: model)
            dataArray.append(bluetoothevent)
        }
        
        if let data = latestWifiData {
            var model = SensorDataModel()
            model.type = SensorType.NearbyDevicetype.wifi
            model.address = data.bssid
            model.name = data.ssid
            model.strength = data.rssi
            let wifiEvent = SensorEvent(timestamp: data.timestamp, sensor: SensorType.lamp_nearby_device.lampIdentifier, data: model)
            dataArray.append(wifiEvent)
            //clear existing
            latestWifiData = nil
        }
        return dataArray
    }
}

// MARK: HealthKit data
private extension LMSensorManager {
    
    func fetchWorkoutSegmentData() -> SensorEvent<SensorDataModel>? {
        guard let arrData = sensor_healthKit?.latestWorkoutData() else {
            return nil
        }
        guard let data = arrData.max(by: { ($0.endDate ?? 0) < ($1.endDate ?? 0) }) else {
            return nil
        }
        var model = SensorDataModel()
        model.type = data.type
        model.duration = data.duration
        
        return SensorEvent(timestamp: Double(data.timestamp), sensor: SensorType.lamp_segment.lampIdentifier, data: model)
    }
    
    func fetchHKCharacteristicData() -> [SensorEvent<SensorDataModel>]? {
        
        guard let arrData = sensor_healthKit?.latestCharacteristicData() else {
            return nil
        }
        
        return arrData.map { (healthData) -> SensorEvent<SensorDataModel> in
            var data = SensorDataModel()
            data.value = healthData.value
            data.representation = healthData.representation
            data.startDate = healthData.startDate
            data.endDate = healthData.endDate
            data.source = healthData.source
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
                        model.representation = categoryData.representation
                        model.startDate = categoryData.startDate
                        model.endDate = categoryData.endDate
                        model.source = categoryData.source
                        model.duration = categoryData.duration
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
                    if let diastolic = dataDiastolic.value {
                        model.diastolic = SensorDataModel.Pressure(value: diastolic, units: dataDiastolic.unit, source: dataDiastolic.source, timestamp: UInt64(dataDiastolic.timestamp))
                    }
                    if let systolic = dataSystolic.value {
                        model.systolic = SensorDataModel.Pressure(value: systolic, units: dataSystolic.unit, source: dataSystolic.source, timestamp: UInt64(dataSystolic.timestamp))
                    }
                    model.startDate = dataSystolic.startDate
                    model.endDate = dataSystolic.endDate
                    arrayData.append(SensorEvent(timestamp: Double(Date().timeInMilliSeconds), sensor: quantityType.lampIdentifier, data: model))
                }
            case .bloodPressureDiastolic:
                ()//handled with Systolic
            default://bodyMass, height, respiratoryRate, heartRate
                if let dataArray = allHealthData(for: quantityType, in: arrData) {
                    let sensorDataArray = dataArray.map { (quantityData) -> SensorEvent<SensorDataModel> in
                        var model = SensorDataModel()
                        model.unit = quantityData.unit
                        //model.type = quantityData.type
                        model.value = quantityData.value
                        //model.startDate = quantityData.startDate
                        //model.endDate = quantityData.endDate
                        model.source = quantityData.source
                        if quantityData.type == HKQuantityTypeIdentifier.bloodGlucose.rawValue {
                            if let mealtime = quantityData.metadata?["HKBloodGlucoseMealTime"] as? Int {
                                switch mealtime {
                                case 0:
                                    model.meal_time = "unspecified"
                                case 1:
                                    model.meal_time = "preprandial"//before meal
                                case 2:
                                    model.meal_time = "postprandial"
                                default:
                                    break
                                }
                            }
                        }
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
