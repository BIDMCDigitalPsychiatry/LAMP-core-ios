//
//  LampSensorCoreObject.swift
//  mindLAMP Consortium
//
//  Created by ZCO Engineer on 13/01/20.
//

import Foundation

public class LampSensorCoreObject {
    
    public var timestamp: Int64 = Int64(Date().timeIntervalSince1970*1000)
    public var label : String = ""
    public var timezone: Int = LampSensorCoreUtils.getTimeZone()
    //public var os: String = "ios"
    //public var jsonVersion: Int = 0
    
    open func toDictionary() -> Dictionary<String, Any> {
        let dict = ["timestamp":timestamp,
                    "label"    :label,
                    "timezone" :timezone] as [String : Any]
                    //"os"       :os,
                    //"jsonVersion":jsonVersion] as [String : Any]
        return dict
    }
    public init() {}
}


