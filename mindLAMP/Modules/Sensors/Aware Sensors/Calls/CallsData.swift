//
//  CallsObject.swift
//  com.aware.ios.sensor.calls
//
//  Created by Yuuki Nishiyama on 2018/10/24.
//

import UIKit

public class CallsData: AwareObject {
    public static var TABLE_NAME = "callsData"
    @objc dynamic public var eventTimestamp: Int64 = 0
    @objc dynamic public var type: Int = -1
    @objc dynamic public var duration: Int64 = 0
    @objc dynamic public var trace:String? = nil
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["eventTimestamp"] = eventTimestamp
        dict["type"] = type
        dict["duration"] = duration
        if let uwTrace = trace {
            dict["trace"] = uwTrace
        }
        return dict
    }
}
