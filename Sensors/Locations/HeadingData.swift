//
//  HeadingData.swift
//  mindLAMP Consortium
//

public class HeadingData: LampSensorCoreObject {
    
    public static var TABLE_NAME = "headingData"

    public var magneticHeading: Double = 0
    public var trueHeading: Double = 0
    public var headingAccuracy: Double = 0
    public var x: Double = 0
    public var y: Double = 0
    public var z: Double = 0

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
