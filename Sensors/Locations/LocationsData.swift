//
//  LocationsData.swift
//  mindLAMP Consortium
//

public class LocationsData: LampSensorCoreObject {
    public static var TABLE_NAME = "locationsData"

    // CLLocationCoordinate2D
    public var latitude:  Double = 0
    public var longitude: Double = 0
    //open var course: CLLocationDirection { get }
    public var course:    Double = 0
    //open var speed: CLLocationSpeed { get }
    public var speed:     Double = 0
    // open var altitude: CLLocationDistance { get }
    public var altitude:  Double = 0
    //open var horizontalAccuracy: CLLocationAccuracy { get }
    public var horizontalAccuracy: Double = 0
    //open var verticalAccuracy: CLLocationAccuracy { get }
    public var verticalAccuracy: Double = 0
    //@NSCopying open var floor: CLFloor? { get }
    public var floor: Int? = 0
    
    override public func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["latitude"]  = latitude
        dict["longitude"] = longitude
        dict["course"]   = course
        dict["speed"]     = speed
        dict["altitude"]  = altitude
        dict["horizontalAccuracy"] = horizontalAccuracy
        dict["verticalAccuracy"]  = verticalAccuracy
        if let floorLevel = floor{
            dict["floor"] = floorLevel
        }
        return dict
    }
}







