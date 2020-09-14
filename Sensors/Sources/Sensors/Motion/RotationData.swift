//
//  RotationData.swift
//  mindLAMP Consortium
//
//  Created by ZCO Engineer on 13/01/20.
//

//import UIKit

public class RotationData: LampSensorCoreObject {
    
    public static var TABLE_NAME = "rotationData"
    
    public var roll : Double = 0.0
    public var pitch : Double = 0.0
    public var yaw : Double = 0.0
    
    public var eventTimestamp:Int64 = 0
    public var accuracy:Int = 0
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["roll"] = roll
        dict["pitch"] = pitch
        dict["yaw"] = yaw
        dict["eventTimestamp"] = eventTimestamp
        dict["accuracy"] = accuracy
        return dict
    }
}
