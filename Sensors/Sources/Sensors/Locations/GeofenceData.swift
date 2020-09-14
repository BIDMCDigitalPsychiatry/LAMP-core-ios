//
//  GeofenceData.swift
//  mindLAMP Consortium
//

public class GeofenceData: LampSensorCoreObject {
    
    public static let TABLE_NAME = "geofenceData"
    
    public var horizontalAccuracy: Double = 0
    public var verticalAccuracy: Double   = 0
    public var latitude:Double            = 0
    public var longitude:Double           = 0

    public var onExit:Bool  = false
    public var onEntry:Bool = false

    public var targetLatitude:Double  = 0
    public var targetLongitude:Double = 0
    public var targetRadius:Double    = 0
    public var identifier:String      = ""

    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["horizontalAccuracy"] = horizontalAccuracy
        dict["verticalAccuracy"]   = verticalAccuracy
        dict["latitude"]           = latitude
        dict["longitude"]          = longitude
        
        dict["onExit"]  = onExit
        dict["onEntry"] = onEntry

        dict["identifier"]         = identifier
        return dict
    }
}
