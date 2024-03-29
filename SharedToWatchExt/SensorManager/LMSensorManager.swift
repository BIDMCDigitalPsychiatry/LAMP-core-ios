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
import SensorKit
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
    //var sensor_wifi: WiFiSensor?
    #endif
    
    #if os(iOS)
    var reachability: Reachability = try! Reachability()
    #endif
    
    var nearByDevice: NearByDevice?
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
    
    //SensorKit Data
    let queueSensorKitBufferData = DispatchQueue(label: "thread-safe-VisitData", attributes: .concurrent)
    var sensorKitDataBuffer: [SensorKitEvent] = []
#if os(iOS)
    var sensorLoader: SRSensorLoader?
#endif
    
    
//    //******define all sensor specs here.**********
//    lazy var allSensorSpecs: [String] = {
//       var sensors = [SensorType.lamp_gps.lampIdentifier,
//                      SensorType.lamp_Activity.lampIdentifier,
//                      SensorType.lamp_telephony.lampIdentifier,
//                      SensorType.lamp_device_state.lampIdentifier,
//                      SensorType.lamp_nearby_device.lampIdentifier,
//                      SensorType.lamp_steps.lampIdentifier,
//                      SensorType.lamp_accelerometer.lampIdentifier,
//                      SensorType.lamp_analytics.lampIdentifier]
//        if Environment.isDiigApp == false {
//            sensors.append(SensorType.lamp_device_motion.lampIdentifier)
//        }
//        sensors.append(contentsOf: LMHealthKitSensor.healthkitSensors)
//#if os(iOS)
//        sensors.append(contentsOf: SRSensorLoader.allLampIdentifiers)
//#endif
//        print("sensors = \(sensors)")
//        return sensors
//    }()
    
    let intervalToFetchSensorConfig = 40.0 * 60.0 //for 1 hour 
    
    func refreshSensorSpecs() {
        if Date().timeIntervalSince(UserDefaults.standard.sensorAPILastAccessedDate) > intervalToFetchSensorConfig {
            fetchSensorSpec()
        }
    }
    
    private func fetchSensorSpec() {
        guard let participantId = User.shared.userId else { return }
        let lampAPI = NetworkConfig.networkingAPI()
        let endPoint =  String(format: Endpoint.sensor.rawValue, participantId)
        let requestData = RequestData(endpoint: endPoint, requestTye: .get)
        lampAPI.makeWebserviceCall(with: requestData) { [weak self] (response: Result<SensorAPI.Response>) in
            guard let self = self else { return }
            UserDefaults.standard.sensorAPILastAccessedDate = Date()
            switch response {
            case .failure(let err):
                if let nsError = err as NSError? {
                    let errorCode = nsError.code
                    // -1009 is the offline error code
                    // so log errors other than connection issue
                    if errorCode == -1009 {
                        LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.network_error + " " + nsError.localizedDescription)
                    } else {
                        LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + nsError.localizedDescription)
                    }
                }
            case .success(let response):
                let sensorSpecs: [Sensor] = response.data
                let identifiers = sensorSpecs.compactMap({ $0.spec })
                if Set(identifiers) != Set(self.sensorIdentifiers) {
                    SensorLogs.shared.storeSensorSpecs(specs: sensorSpecs)
                    //load sensorspec after api call.
                    DispatchQueue.main.async {
                        self.loadSensorSpecs()
                    }
                }
            }
        }
    }
    
    private init() {
        
        #if os(iOS)
        NotificationCenter.default.addObserver(self, selector: #selector(powerStateChanged), name: Notification.Name.NSProcessInfoPowerStateDidChange, object: nil)
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
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name.NSProcessInfoPowerStateDidChange,
                                                  object: nil)
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
        #endif
    }
    
    @objc func powerStateChanged(_ notification: Notification) {
        let lowerPowerEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        // take appropriate action
        
        //post as sensor data
        let sensorData = SensorDataModel(action: SensorType.AnalyticAction.lowpowermode.rawValue, userAgent: UserAgent.defaultAgent, value: lowerPowerEnabled)
        
        let event = SensorEvent(timestamp: Date().timeInMilliSeconds, sensor: SensorType.lamp_analytics.lampIdentifier, data: sensorData)

        let request = SensorData.Request(sensorEvents: [event])
        if lowerPowerEnabled {
            guard let participantId = User.shared.userId else {
                return
            }
            let lampAPI = NetworkConfig.networkingAPI()
            let endPoint = String(format: Endpoint.participantSensorEvent.rawValue, participantId)
            let data = RequestData(endpoint: endPoint, requestTye: HTTPMethodType.post, data: request)
            lampAPI.makeWebserviceCall(with: data) { (response: Result<SensorData.Response>) in
                switch response {
                case .success:
                    ()
                case .failure:
                    SensorLogs.shared.storeSensorRequest(request, fileNameWithoutExt: "\(UserDefaults.standard.lpmCount)")
                }
            }
        } else {
            SensorLogs.shared.storeSensorRequest(request, fileNameWithoutExt: "\(UserDefaults.standard.lpmCount)")
        }
        
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
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Reachability"), object: nil)
        case .cellular:
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Reachability"), object: nil)
            isReachableViaWiFi = false
        case .unavailable:
            isReachableViaWiFi = false
        }
        #endif
    }
    
    private func initiateSensors() {
        
        isStarted = true
        //Always setup location sensors to keep the app alive in background. but collect location data only if its configured.
        print("sensorIdentifiers = \(sensorIdentifiers)")
        setupLocationSensor(isNeedData: sensorIdentifiers.contains(SensorType.lamp_gps.lampIdentifier))
        
        let isExist = setUpSensorMotionManager(sensorIdentifiers)
        
        sensorAPITimer = nil
        if isExist {
            // then we are using the timer of motion to store/sync sensor data to server
        } else {
            runevery(seconds: storeSensorDataIntervalInMinutes * 60)
        }
        
        #if os(iOS)
        //set up new sensorkit
        setupSensorKitSensors(sensorIdentifiers)
        
        if sensorIdentifiers.contains(SensorType.lamp_Activity.lampIdentifier) {
            setupActivitySensor()
        }
        if sensorIdentifiers.contains(SensorType.lamp_telephony.lampIdentifier) {
            setupCallsSensor()
        }
        if sensorIdentifiers.contains(SensorType.lamp_screen_state.lampIdentifier) || sensorIdentifiers.contains(SensorType.lamp_device_state.lampIdentifier) {
            UIDevice.current.isBatteryMonitoringEnabled = true
            setupScreenSensor()
        }
        if sensorIdentifiers.contains(SensorType.lamp_nearby_device.lampIdentifier) {
            setupNearBySensor()
        }
        
        setupHealthKitSensor(sensorIdentifiers)
        
        if sensorIdentifiers.contains(SensorType.lamp_steps.lampIdentifier) {
            setupPedometerSensor()
        }
        #endif
    }
    
    private func deinitSensors() {
        
        sensor_motionManager = nil
        nearByDevice = nil
        sensor_healthKit = nil
        sensor_location = nil
        
        sensor_Activity = nil
        sensor_pedometer = nil
        #if os(iOS)
        sensor_calls = nil
        lampScreenSensor = nil
        #endif
    }
    
    //var subscriber: AnyCancellable?
    var sensorIdentifiers: [String] = []
    /// To start sensors observing.
    private func startSensors() {
        
        guard let participantId = User.shared.userId else {
            self.isStarted = false
            return }
        let lampAPI = NetworkConfig.networkingAPI()
        let endPoint =  String(format: Endpoint.sensor.rawValue, participantId)
        let requestData = RequestData(endpoint: endPoint, requestTye: .get)
        lampAPI.makeWebserviceCall(with: requestData) { (response: Result<SensorAPI.Response>) in
            switch response {
            case .failure(let err):
                if let nsError = err as NSError? {
                    let errorCode = nsError.code
                    // -1009 is the offline error code
                    // so log errors other than connection issue
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
            UserDefaults.standard.sensorAPILastAccessedDate = Date()
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
        stopSensors(islogout: false)
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
            sensorIdentifiers = [] //allSensorSpecs //collect no sensors if nothing is configured
            frquencySettings = [:]
        }
        self.initiateSensors()
        self.sensorManager.startAllSensors()
    }
    
    func startWatchSensors() {
        #if os(iOS)
        //send a message to watch to collect sensor data
        let messageInfo: [String: Any] = [IOSCommands.sendWatchSensorEvents : true, IOSCommands.timestamp : Date().timeInMilliSeconds]
        WatchSessionManager.shared.updateApplicationContext(applicationContext: (messageInfo))
        #endif
    }

    // To stop sensors observing.
    func stopSensors(islogout: Bool) {

        sensorIdentifiers.removeAll()
        isStarted = false
        sensorAPITimer = nil
        
        sensorManager.stopAllSensors()
        sensorManager.clear()
        
        if islogout {
            sensor_pedometer?.removeSavedTimestamps()
            sensor_healthKit?.removeSavedTimestamps()
            #if os(iOS)
            sensorLoader?.removeSavedTimestamps()
            #endif
            sensor_healthKit?.clearDataArrays()
        }

        deinitSensors()
        
        //clear the bufffers
        activityDataBuffer.removeAll()
        accelerometerDataBufffer.removeAll()
        callsDataBuffer.removeAll()
        motionDataBuffer.removeAll()
        pedometerDataBuffer.removeAll()
        locationsDataBuffer.removeAll()
        screenStateDataBuffer.removeAll()
        // sensorKitDataBuffer
    }
    
    func getSensorDataRequest() -> SensorData.Request? {
        let events = getSensorDataArrray()
        if events.count > 0 {
            return SensorData.Request(sensorEvents: events)
        }
        return nil
    }
    
    func getSensorKitRequest() -> Data? {
        let sensorKitDataArray = getSensorKitArrray()
        
        return SensorKitData.Request(sensorEvents: sensorKitDataArray).toData()
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
    
    var isRunning: Bool {
        isStarted
    }
    
    func checkIsRunning() {
        guard User.shared.isLogin() else {
            printToFile("\nNot logined")
            return }
        if self.isStarted == false {
            print("\nstartSensors")
            self.isStarted = true
            startSensors()

            // runevery(seconds: storeSensorDataIntervalInMinutes * 60)
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
        let alertController = UIAlertController(title: "alert.location.title".localized, message: "alert.location.message".localized, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "alert.button.settings".localized, style: .default, handler: {(cAlertAction) in
            //Redirect to Settings app
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
        })
        
        let cancelAction = UIAlertAction(title: "alert.button.cancel".localized, style: .cancel)
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
                
                if Environment.isDiigApp {
                    config.pausePeriod = 3
                    config.collectionPeriod = 1
                }
                
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
    
    func setupNearBySensor() {
        nearByDevice = NearByDevice(NearByDevice.Config().apply(closure: { config in
            if let frquency = frquencySettings[SensorType.lamp_nearby_device.lampIdentifier] {
                config.frequency = frquency
            }
        }))
        sensorManager.addSensor(nearByDevice!)
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
    
    func setupSensorKitSensors(_ specIdentifiers: [String]) {
        #if os(iOS)
        
        // For now, please restrict these sensor types to only the server addresses from the domain group *.lamp.digital.
        if UIDevice.current.userInterfaceIdiom != .pad && UserDefaults.standard.serverAddressShared?.hasSuffix(".lamp.digital") == true {
            let sensorKitSensors = SRSensorLoader.allLampIdentifiers
            let sensorKitSpecIdentifier = specIdentifiers.filter({ sensorKitSensors.contains($0) })
            if sensorKitSpecIdentifier.count > 0 {
                let frequencies = frquencySettings.filter({ sensorKitSensors.contains($0.key) })
                sensorLoader = SRSensorLoader(sensorKitSpecIdentifier, frquencySettings: frequencies)
                sensorLoader?.observer = self
                sensorManager.addSensor(sensorLoader!)
            }
        }
        
        #endif
    }
    
    func setupLocationSensor(isNeedData: Bool) {
      sensor_location = LocationsSensor.init(LocationsSensor.Config().apply(closure: { config in
            #if os(iOS)
            config.sensorObserver = self
            if isNeedData {
                config.locationDataObserver = self
                config.accuracy = kCLLocationAccuracyBestForNavigation
            } else {
                config.accuracy = kCLLocationAccuracyReduced
            }
            if let frquency = frquencySettings[SensorType.lamp_gps.lampIdentifier] {
                config.frequency = frquency
            } else {
                if Environment.isDiigApp {
                    config.frequency = 1.0 / 600.0
                }
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
    #endif
}

// MARK: Fetch data as per confoguration
private extension LMSensorManager {
    
    func getSensorKitArrray() -> [SensorKitEvent] {
        var arraySensorKitData = [SensorKitEvent]()
        arraySensorKitData.append(contentsOf: fetchSensorData())
        return arraySensorKitData
    }
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
        if let data = fetchBPData() {
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
// MARK: sensors data fetch
private extension LMSensorManager {
    func fetchSensorData() -> [SensorKitEvent] {
        // read
        var dataArray: [SensorKitEvent]!
        queueSensorKitBufferData.sync {
            // perform read and assign value
            dataArray = sensorKitDataBuffer
        }
        queueSensorKitBufferData.async(flags: .barrier) {
            self.sensorKitDataBuffer.removeAll(keepingCapacity: true)
        }
        return dataArray
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
        
        let sensorArray = dataArray.map { SensorEvent(timestamp: $0.timestamp, sensor: SensorType.lamp_device_state.lampIdentifier, data: SensorDataModel(screenData: $0)) }
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
        if let dataa = nearByDevice?.latestBluetoothData() {
            dataa.forEach { data in
                var model = SensorDataModel()
                model.type = SensorType.NearbyDevicetype.bluetooth
                model.address = data.address
                model.name = data.name
                model.strength = data.rssi
                let bluetoothevent = SensorEvent(timestamp: data.timestamp, sensor: SensorType.lamp_nearby_device.lampIdentifier, data: model)
                dataArray.append(bluetoothevent)
            }
            
        }
        
        if let dataa = nearByDevice?.latestWifiData() {
            dataa.forEach { data in
                var model = SensorDataModel()
                model.type = SensorType.NearbyDevicetype.wifi
                model.address = data.bssid
                model.name = data.ssid
                model.strength = data.rssi
                let wifiEvent = SensorEvent(timestamp: data.timestamp, sensor: SensorType.lamp_nearby_device.lampIdentifier, data: model)
                dataArray.append(wifiEvent)
            }
            
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
            data.source = Tristate(healthData.source)
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
                        model.source = Tristate(categoryData.source)
                        model.duration = categoryData.duration
                        return SensorEvent(timestamp: Double(categoryData.timestamp), sensor: categoryType.lampIdentifier, data: model)
                    }
                }
            }
        }
        return arrayData
    }
    
    func fetchBPData() -> [SensorEvent<SensorDataModel>]? {
        guard let arrData = sensor_healthKit?.latestBPData() else {
            return nil
        }

        return arrData.compactMap { bpdata in
            
            if let sys = bpdata.systolic, let dias = bpdata.diastolic {
                var model = SensorDataModel()
                model.diastolic = SensorDataModel.Pressure(value: dias, units: bpdata.unit, source: bpdata.source, timestamp: UInt64(bpdata.timestamp))
                model.systolic = SensorDataModel.Pressure(value: sys, units: bpdata.unit, source: bpdata.source, timestamp: UInt64(bpdata.timestamp))
                model.startDate = bpdata.startDate
                model.endDate = bpdata.endDate
                model.source = Tristate(bpdata.source)
                model.device_model = Tristate(bpdata.hkDevice)
                return SensorEvent(timestamp: Double(Date().timeInMilliSeconds), sensor: bpdata.hkIdentifier.lampIdentifier, data: model)
            }
            return nil
        }
    }

    func fetchHealthKitQuantityData() -> [SensorEvent<SensorDataModel>]? {
        guard let arrData = sensor_healthKit?.latestQuantityData() else {
            return nil
        }
        var arrayData = [SensorEvent<SensorDataModel>]()
        
        guard let quantityTypes: [HKQuantityTypeIdentifier] = sensor_healthKit?.healthQuantityTypes(isForAuthoroization: false).map( {HKQuantityTypeIdentifier(rawValue: $0.identifier)} ) else { return nil }
        for quantityType in quantityTypes {
            switch quantityType {
            
            case .bloodPressureSystolic:
                ()
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
                        model.source = Tristate(quantityData.source)
                        model.device_model = Tristate(quantityData.hkDevice)
                        if quantityData.type == HKQuantityTypeIdentifier.stepCount.rawValue {
                            model.type = PedometerData.SensorType.step_count.rawValue
                        }
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
