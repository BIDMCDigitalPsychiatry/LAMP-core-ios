// mindLAMP

import Foundation

public class AttitudeData: LampSensorCoreObject {
    
    public static var TABLE_NAME = "AttitudeData"
    
    @objc dynamic public var eventTimestamp : Int64 = 0
    @objc dynamic public var roll : Double = 0.0
    @objc dynamic public var pitch : Double = 0.0
    @objc dynamic public var yaw : Double = 0.0
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["roll"] = roll
        dict["pitch"] = pitch
        dict["yaw"] = yaw
        dict["eventTimestamp"] = eventTimestamp
        return dict
    }
}

