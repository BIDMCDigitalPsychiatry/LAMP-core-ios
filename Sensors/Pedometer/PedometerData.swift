//
//  PedometerData.swift
//  mindLAMP Consortium
//

//import UIKit

public class PedometerData: LampSensorCoreObject {
    public static let TABLE_NAME = "pedometerData"
    
    public var startDate:Int64 = 0;
    public var endDate:Int64  = 0;
    public var frequencySpeed:Double  = 0;
    public var numberOfSteps:Int   = 0;
    public var distance:Double        = 0;
    public var currentPace:Double     = 0;
    public var currentCadence:Double  = 0;
    public var floorsAscended:Int  = 0;
    public var floorsDescended:Int = 0;
    public var averageActivePace:Double = 0;
    
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
