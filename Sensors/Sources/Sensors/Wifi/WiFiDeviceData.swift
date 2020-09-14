//
//  WifiData.swift
//  mindLAMP Consortium
//


public class WiFiDeviceData: LampSensorCoreObject {

    public var macAddress: String? = nil
    public var bssid: String? = nil
    public var ssid: String? = nil
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["macAddress"] = macAddress
        dict["bssid"] = bssid
        dict["ssid"] = ssid
        return dict
    }
    
}
 
