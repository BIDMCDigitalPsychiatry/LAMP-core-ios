//
//  GravityData.swift
//  com.aware.ios.sensor.gravity
//
//  Created by Yuuki Nishiyama on 2018/11/01.
//

import UIKit

public class GravityData: AwareObject {
    public static var TABLE_NAME = "gravityData"
    
    @objc dynamic public var x:Double = 0.0
    @objc dynamic public var y:Double = 0.0
    @objc dynamic public var z:Double = 0.0
    @objc dynamic public var eventTimestamp:Int64 = 0
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["x"] = x
        dict["y"] = y
        dict["z"] = z
        dict["eventTimestamp"] = eventTimestamp
        return dict
    }
}
