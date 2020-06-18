//
//  ScreenData.swift
//  com.lamp.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2018/10/23.
//

import UIKit

public class ScreenData: LampSensorCoreObject {
    public static var TABLE_NAME = "screenData"
    
    @objc dynamic public var screenStatus:Int = -1
    
    override public func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["screenStatus"] = screenStatus
        return dict
    }
}
