//
//  GeofenceData.swift
//  com.awareframework.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2018/12/07.
//

import UIKit

public class GeofenceData: AwareObject {
    
    public static let TABLE_NAME = "geofenceData"
    
    @objc dynamic public var horizontalAccuracy: Double = 0
    @objc dynamic public var verticalAccuracy: Double   = 0
    @objc dynamic public var latitude:Double            = 0
    @objc dynamic public var longitude:Double           = 0

    @objc dynamic public var onExit:Bool  = false
    @objc dynamic public var onEntry:Bool = false

    @objc dynamic public var targetLatitude:Double  = 0
    @objc dynamic public var targetLongitude:Double = 0
    @objc dynamic public var targetRadius:Double    = 0
    @objc dynamic public var identifier:String      = ""

    
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
