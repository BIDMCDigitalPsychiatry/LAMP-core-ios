//
//  Wifi.swift
//  com.aware.ios.sensor.wifi
//
//  Created by Yuuki Nishiyama on 2018/10/18.
//

import UIKit
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

extension Notification.Name {
    public static let actionLampWiFiStart    = Notification.Name(WiFiSensor.ACTION_LAMP_WIFI_START)
    public static let actionLampWiFiStop     = Notification.Name(WiFiSensor.ACTION_LAMP_WIFI_STOP)
    public static let actionLampWiFiSync     = Notification.Name(WiFiSensor.ACTION_LAMP_WIFI_SYNC)
    public static let actionLampWiFiSyncCompletion     = Notification.Name(WiFiSensor.ACTION_LAMP_WIFI_SYNC_COMPLETION)
    public static let actionLampWiFiSetLabel = Notification.Name(WiFiSensor.ACTION_LAMP_WIFI_SET_LABEL)
    
    public static let actionLampWiFiCurrentAP   = Notification.Name(WiFiSensor.ACTION_LAMP_WIFI_CURRENT_AP)
    public static let actionLampWiFiNewDevice   = Notification.Name(WiFiSensor.ACTION_LAMP_WIFI_NEW_DEVICE)
    public static let actionLampWiFiScanStarted = Notification.Name(WiFiSensor.ACTION_LAMP_WIFI_SCAN_STARTED)
    public static let actionLampWiFiScanEnded   = Notification.Name(WiFiSensor.ACTION_LAMP_WIFI_SCAN_ENDED)
}

public protocol WiFiObserver{
    func onWiFiAPDetected(data: WiFiScanData)
    func onWiFiDisabled()
    func onWiFiScanStarted()
    func onWiFiScanEnded()
}

public class WiFiSensor: LampSensorCore {

    public static let TAG = "LAMP::WiFi"
    
    /**
     * Received event: Fire it to start the WiFi sensor.
     */
    public static let ACTION_LAMP_WIFI_START = "com.aware.sensor.wifi.SENSOR_START"
    
    /**
     * Received event: Fire it to stop the WiFi sensor.
     */
    public static let ACTION_LAMP_WIFI_STOP = "com.aware.sensor.wifi.SENSOR_STOP"
    
    /**
     * Received event: Fire it to sync the data with the server.
     */
    public static let ACTION_LAMP_WIFI_SYNC = "com.aware.sensor.wifi.SYNC"
    
    /**
     * Received event: Fire it to set the data label.
     * Use [EXTRA_LABEL] to send the label string.
     */
    public static let ACTION_LAMP_WIFI_SET_LABEL = "com.aware.sensor.wifi.SET_LABEL"
    
    /**
     * Label string sent in the intent extra.
     */
    public static let EXTRA_LABEL = "label"
    
    /**
     * Fired event: currently connected to this AP
     */
    public static let ACTION_LAMP_WIFI_CURRENT_AP = "ACTION_AWARE_WIFI_CURRENT_AP"
    
    /**
     * Fired event: new WiFi AP device detected.
     * [WiFiSensor.EXTRA_DATA] contains the JSON version of the discovered device.
     */
    public static let ACTION_LAMP_WIFI_NEW_DEVICE = "ACTION_AWARE_WIFI_NEW_DEVICE"
    
    /**
     * Contains the JSON version of the discovered device.
     */
    public static let EXTRA_DATA = "data"
    
    /**
     * Fired event: WiFi scan started.
     */
    public static let ACTION_LAMP_WIFI_SCAN_STARTED = "ACTION_AWARE_WIFI_SCAN_STARTED"
    
    /**
     * Fired event: WiFi scan ended.
     */
    public static let ACTION_LAMP_WIFI_SCAN_ENDED = "ACTION_AWARE_WIFI_SCAN_ENDED"
    
    /**
     * Broadcast receiving event: request a WiFi scan
     */
    public static let ACTION_LAMP_WIFI_REQUEST_SCAN = "ACTION_AWARE_WIFI_REQUEST_SCAN"
    
    public static let ACTION_LAMP_WIFI_SYNC_COMPLETION = "com.awareframework.ios.sensor.wifi.SENSOR_SYNC_COMPLETION"
    public static let EXTRA_STATUS = "status"
    public static let EXTRA_ERROR = "error"
    public static let EXTRA_OBJECT_TYPE = "objectType"
    public static let EXTRA_TABLE_NAME = "tableName"
    
    public var CONFIG = Config()
    
    let reachability = try! Reachability()
    
    var timer:Timer? = nil
    
    public class Config:SensorConfig{
      
        public var sensorObserver:WiFiObserver?
        
        // public var interval: Int = 1 // min
        public var interval: Int = 1 {
            didSet {
                if self.interval < 1{
                    print("[WiFi][Illegal Parameter] The interval value has to be greater than or equal to 1.")
                    self.interval = 1
                }
            }
        }
        
        public override init() {
            super.init()
            //self.dbPath = "aware_wifi"
        }
        
        public func apply(closure:(_ config:WiFiSensor.Config) -> Void ) -> Self {
            closure(self)
            return self
        }
        
        public override func set(config: Dictionary<String, Any>) {
            super.set(config: config)
            if let interval = config["interval"] as? Int {
                self.interval = interval
            }
        }
    }
    
    public override convenience init(){
        self.init(WiFiSensor.Config())
    }
    
    public init(_ config:WiFiSensor.Config){
        super.init()
        CONFIG = config
        initializeDbEngine(config: config)
    }
    
    public override func start() {
        
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: Double(CONFIG.interval)*60.0, repeats: true, block: { timer in
                
                self.notificationCenter.post(name: .actionLampWiFiScanStarted, object: self)
                if let observer = self.CONFIG.sensorObserver{
                    observer.onWiFiScanStarted()
                }
                
                
                if self.reachability.connection == .wifi {
                    let networkInfos = self.getNetworkInfos()
                    
                    for info in networkInfos{
                        // send a WiFiScanData via observer
                        let scanData = WiFiScanData.init()
                        scanData.label = self.CONFIG.label
                        scanData.ssid = info.ssid
                        scanData.bssid = info.bssid
                        
                        if let engine = self.dbEngine {
                            engine.save(scanData)
                        }
                        if let wifiObserver = self.CONFIG.sensorObserver {
                            wifiObserver.onWiFiAPDetected(data: scanData)
                        }
                        self.notificationCenter.post(name: .actionLampWiFiNewDevice,
                                                     object: self,
                                                     userInfo: [WiFiSensor.EXTRA_DATA: scanData.toDictionary()])
                    }
                }
                
                
                Timer.scheduledTimer(withTimeInterval: 60, repeats: false, block: { timer in
                    self.notificationCenter.post(name: .actionLampWiFiScanEnded, object: self)
                    if let observer = self.CONFIG.sensorObserver{
                        observer.onWiFiScanEnded()
                    }
                })
            })
        }
        
        // start WiFi reachability/unreachable monitoring
        do{
            // reachable events
            reachability.whenReachable = { reachability in
                switch reachability.connection {
                case .wifi:
                    let networkInfos = self.getNetworkInfos()
                    for info in networkInfos{
                        // send a WiFiScanData via observer
                        let scanData = WiFiScanData.init()
                        scanData.label = self.CONFIG.label
                        scanData.ssid = info.ssid
                        scanData.bssid = info.bssid
                        if let observer = self.CONFIG.sensorObserver {
                            observer.onWiFiAPDetected(data: scanData)
                        }
                        // save a WiFiDeviceData info to the local-storage
                        if let engin = self.dbEngine {
                            let deviceData = WiFiDeviceData()
                            deviceData.label = self.CONFIG.label
                            deviceData.bssid = scanData.bssid
                            deviceData.ssid = scanData.ssid
                            engin.save(deviceData)
                            self.notificationCenter.post(name: .actionLampWiFiCurrentAP,
                                                         object: self,
                                                         userInfo: [WiFiSensor.EXTRA_DATA: deviceData.toDictionary()])
                        }
                    }
                    
                    break
                case .cellular, .none:
                    if let observer = self.CONFIG.sensorObserver {
                        observer.onWiFiDisabled()
                    }
                    break
                case .unavailable:
                    break
                }
            }
            try reachability.startNotifier()
        } catch {
            print("\(WiFiSensor.TAG)\(error)")
        }
        
        self.notificationCenter.post(name: .actionLampWiFiStart, object: self)
    }
    
    public override func stop() {
        
        if let uwTimer = timer {
            uwTimer.invalidate()
            timer = nil
        }
        
        reachability.stopNotifier()
        
        self.notificationCenter.post(name: .actionLampWiFiStop, object: self)
    }
    
    public override func sync(force: Bool = false) {
        self.notificationCenter.post(name: .actionLampWiFiSync, object: self)
    }
    
    //////////////////////////////////
    
    struct NetworkInfo {
        public let interface:String
        public let ssid:String
        public let bssid:String
        init(_ interface:String, _ ssid:String,_ bssid:String) {
            self.interface = interface
            self.ssid = ssid
            self.bssid = bssid
        }
    }
    
    func getNetworkInfos() -> Array<NetworkInfo> {
        // https://forums.developer.apple.com/thread/50302
        guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else {
            return []
        }
        let networkInfos:[NetworkInfo] = interfaceNames.compactMap{ name in
            guard let info = CNCopyCurrentNetworkInfo(name as CFString) as? [String:AnyObject] else {
                return nil
            }
            guard let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
                return nil
            }
            guard let bssid = info[kCNNetworkInfoKeyBSSID as String] as? String else {
                return nil
            }
            return NetworkInfo(name, ssid,bssid)
        }
        return networkInfos
    }
    
    public override func set(label:String){
        self.CONFIG.label = label
        self.notificationCenter.post(name: .actionLampWiFiSetLabel, object: self, userInfo: [WiFiSensor.EXTRA_LABEL:label])
    }
}

