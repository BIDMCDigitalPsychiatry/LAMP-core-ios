//
//  HeadingData.swift
//  com.awareframework.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2019/10/14.
//

import UIKit

public class HeadingData: AwareObject {
    
    public static var TABLE_NAME = "headingData"

    @objc dynamic public var magneticHeading: Double = 0
    @objc dynamic public var trueHeading: Double = 0
    @objc dynamic public var headingAccuracy: Double = 0
    @objc dynamic public var x: Double = 0
    @objc dynamic public var y: Double = 0
    @objc dynamic public var z: Double = 0

    override public func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["headingAccuracy"] = headingAccuracy
        dict["trueHeading"] = trueHeading
        dict["magneticHeading"] = magneticHeading
        dict["x"] = x
        dict["y"] = y
        dict["z"] = z
        return dict
    }

}
