//
//  LMHealthKitSensorData.swift
//  mindLAMP
//
//  Created by Zco Engineer on 13/03/20.
//

import Foundation

class LMHealthKitSensorData: AwareObject {
    
    @objc dynamic public var device: [String: Any]?
    @objc dynamic public var startDate:Int64 = 0
    @objc dynamic public var endDate:Int64   = 0
    @objc dynamic public var metadata: [String: Any]?
    @objc dynamic public var type:String     = ""  // eg: HKQuantityTypeIdentifier
    @objc dynamic public var value:Double    = 0  // e.g., 60
    @objc dynamic public var unit:String     = "" // e.g., count/min

    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["device"]    = device
        dict["startDate"] = startDate
        dict["endDate"]   = endDate
        dict["metadata"]  = metadata
        dict["type"]      = type
        dict["value"]     = value
        dict["unit"]      = unit
        return dict
    }
}
