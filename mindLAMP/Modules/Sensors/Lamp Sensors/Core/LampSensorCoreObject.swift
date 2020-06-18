//
//  AwareRealmObject.swift
//  aware-core
//
//  Created by Yuuki Nishiyama on 2018/01/01.
//  Copyright © 2018 Yuuki Nishiyama. All rights reserved.
//

import Foundation

open class LampSensorCoreObject {
    
    @objc dynamic public var timestamp: Int64 = Int64(Date().timeIntervalSince1970*1000)
    @objc dynamic public var deviceId: String = LampSensorCoreUtils.getCommonDeviceId()
    @objc dynamic public var label : String = ""
    @objc dynamic public var timezone: Int = LampSensorCoreUtils.getTimeZone()
    @objc dynamic public var os: String = "ios"
    @objc dynamic public var jsonVersion: Int = 0
    
    open func toDictionary() -> Dictionary<String, Any> {
        let dict = ["timestamp":timestamp,
                    "deviceId" :deviceId,
                    "label"    :label,
                    "timezone" :timezone,
                    "os"       :os,
                    "jsonVersion":jsonVersion] as [String : Any]
        return dict
    }
}


