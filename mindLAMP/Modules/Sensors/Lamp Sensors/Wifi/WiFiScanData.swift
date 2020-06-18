//
//  WiFiScanData.swift
//  com.lamp.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2018/10/23.
//

import UIKit

public class WiFiScanData: LampSensorCoreObject {
    public static var TABLE_NAME = "wifiScanData"
    
    @objc dynamic public var bssid: String = ""
    @objc dynamic public var ssid: String  = ""
    @objc dynamic public var security: String = ""
    @objc dynamic public var frequency: Int = 0
    @objc dynamic public var rssi: Int = 0
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["bssid"] = bssid
        dict["ssid"] = ssid
        dict["security"] = security
        dict["frequency"] = frequency
        dict["rssi"] = rssi
        return dict
    }
}
