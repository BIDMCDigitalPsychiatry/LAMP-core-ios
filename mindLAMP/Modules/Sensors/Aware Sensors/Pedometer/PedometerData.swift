//
//  PedometerData.swift
//  com.aware.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2018/11/12.
//

import UIKit

public class PedometerData: LampSensorCoreObject {
    public static let TABLE_NAME = "pedometerData"
    
    @objc dynamic public var startDate:Int64 = 0;
    @objc dynamic public var endDate:Int64  = 0;
    @objc dynamic public var frequencySpeed:Double  = 0;
    @objc dynamic public var numberOfSteps:Int   = 0;
    @objc dynamic public var distance:Double        = 0;
    @objc dynamic public var currentPace:Double     = 0;
    @objc dynamic public var currentCadence:Double  = 0;
    @objc dynamic public var floorsAscended:Int  = 0;
    @objc dynamic public var floorsDescended:Int = 0;
    @objc dynamic public var averageActivePace:Double = 0;
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["startDate"] = startDate
        dict["endDate"]   = endDate
        dict["frequencySpeed"]  = frequencySpeed
        dict["numberOfSteps"]   = numberOfSteps
        dict["distance"]        = distance
        dict["currentPace"]     = currentPace
        dict["currentCadence"]  = currentCadence
        dict["floorsAscended"]  = floorsAscended
        dict["floorsDescended"] = floorsDescended
        dict["averageActivePace"] = averageActivePace
        return dict
    }
    
}
