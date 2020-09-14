//
//  CallsObject.swift
//  mindLAMP Consortium
//

public class CallsData: LampSensorCoreObject {
    public static var TABLE_NAME = "callsData"
    public var eventTimestamp: Int64 = 0
    public var type: Int = -1
    public var duration: Int64 = 0
    public var trace:String? = nil
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["eventTimestamp"] = eventTimestamp
        dict["type"] = type
        dict["duration"] = duration
        if let uwTrace = trace {
            dict["trace"] = uwTrace
        }
        return dict
    }
}
