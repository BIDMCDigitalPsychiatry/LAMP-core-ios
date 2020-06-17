//
//  RotationData.swift
//  com.aware.ios.sensor.rotation
//
//  Created by Yuuki Nishiyama on 2018/10/30.
//

import UIKit

public class RotationData: LampSensorCoreObject {
    
    public static var TABLE_NAME = "rotationData"
    
    @objc dynamic public var x:Double = 0.0
    @objc dynamic public var y:Double = 0.0
    @objc dynamic public var z:Double = 0.0
    @objc dynamic public var w:Double = 0.0 // iOS does not support the value
    @objc dynamic public var eventTimestamp:Int64 = 0
    @objc dynamic public var accuracy:Int = 0
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["x"] = x
        dict["y"] = y
        dict["z"] = z
        dict["w"] = w
        dict["eventTimestamp"] = eventTimestamp
        dict["accuracy"] = accuracy
        return dict
    }
}
