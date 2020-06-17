//
//  VisitData.swift
//  com.awareframework.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2018/12/07.
//

import UIKit

public class VisitData: LampSensorCoreObject {
    
    public static let TABLE_NAME = "visitData"
    
    @objc dynamic public var horizontalAccuracy: Double = 0
    @objc dynamic public var latitude:Double = 0
    @objc dynamic public var longitude:Double = 0
    @objc dynamic public var name:String = ""
    @objc dynamic public var address:String = ""
    @objc dynamic public var departure:Int64 = 0
    @objc dynamic public var arrival:Int64 = 0
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["horizontalAccuracy"] = horizontalAccuracy
        dict["latitude"] = latitude
        dict["longitude"] = longitude
        dict["name"] = name
        dict["address"] = address
        dict["departure"] = departure
        dict["arrival"] = arrival
        return dict
    }
}
