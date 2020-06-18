//
//  WifiData.swift
//  com.lamp.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2018/10/18.
//

import UIKit

public class WiFiDeviceData: LampSensorCoreObject {
    
    public static var TABLE_NAME = "wifiDeviceData"
    
    @objc dynamic public var macAddress: String? = nil
    @objc dynamic public var bssid: String? = nil
    @objc dynamic public var ssid: String? = nil
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["macAddress"] = macAddress
        dict["bssid"] = bssid
        dict["ssid"] = ssid
        return dict
    }
    
}
