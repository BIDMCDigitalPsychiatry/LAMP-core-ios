//
//  GyroscopeData.swift
//  mindLAMP Consortium
//


public class GyroscopeData: LampSensorCoreObject {
    public static var TABLE_NAME = "gyroscopeData"
    
    public var eventTimestamp : Int64 = 0
    public var x : Double = 0.0
    public var y : Double = 0.0
    public var z : Double = 0.0
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["x"] = x
        dict["y"] = y
        dict["z"] = z
        dict["eventTimestamp"] = eventTimestamp
        return dict
    }
}
