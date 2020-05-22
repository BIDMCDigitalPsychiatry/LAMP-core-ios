//
//  LMHealthKitSensorData.swift
//  mindLAMP
//
//  Created by Zco Engineer on 13/03/20.
//

import Foundation

class LMHealthKitSensorData: AwareObject {
    
    public var device: [String: Any]?
    public var startDate: Double?
    public var endDate: Double?
    public var metadata: [String: Any]?
    public var type: String = ""  // eg: HKQuantityTypeIdentifier
    public var value: Double?  // e.g., 60
    public var valueText: String?  // e.g., 60
    public var unit: String? // e.g., count/min
    public var lampIdentifier: String = ""

    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["device"] = device
        dict["startDate"] = startDate
        dict["endDate"] = endDate
        dict["metadata"] = metadata
        dict["type"] = type
        dict["value"] = value
        dict["valueText"] = valueText
        dict["unit"] = unit
        dict["lampIdentifier"] = lampIdentifier
        return dict
    }
}
