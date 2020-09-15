//
//  VisitData.swift
//  mindLAMP Consortium
//

public class VisitData: LampSensorCoreObject {
    
    public static let TABLE_NAME = "visitData"
    
    public var horizontalAccuracy: Double = 0
    public var latitude:Double = 0
    public var longitude:Double = 0
    public var name:String = ""
    public var address:String = ""
    public var departure:Int64 = 0
    public var arrival:Int64 = 0
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["horizontalAccuracy"] = horizontalAccuracy
        dict["latitude"] = latitude
        dict["longitude"] = longitude
        dict["name"] = name
        dict["address"] = address
        dict["departure"] = departure
        dict["arrival"] = arrival
        return dict
    }
}
