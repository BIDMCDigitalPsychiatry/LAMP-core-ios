//
//  WiFiScanData.swift
//  mindLAMP Consortium
//

public class WiFiScanData: LampSensorCoreObject {
    public static var TABLE_NAME = "wifiScanData"
    
    public var bssid: String = ""
    public var ssid: String  = ""
    public var security: String = ""
    public var frequency: Int = 0
    public var rssi: Int = 0
    
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
