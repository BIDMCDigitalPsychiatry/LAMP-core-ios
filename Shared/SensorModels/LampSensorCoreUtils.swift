//
//  AwareUtils.swift
//  CoreAware
//
//  Created by Yuuki Nishiyama on 2018/03/04.
//

import Foundation
import UIKit

public class LampSensorCoreUtils{

    private static let kDeviceIdKey:String = "com.lamp.ios.sensor.core.key.deviceid"
    
    public static func getTimeZone() -> Int {
        let secondsFromGMT = TimeZone.current.secondsFromGMT()
        return secondsFromGMT/60/60 // convert a secounds -> hours
    }
        
    /**
     * Remove "http://" and "https://" if the protocol is included in the "host" name.
     */
    public static func cleanHostName(_ hostName:String) -> String {
        var newHostName = hostName;
        if let range = newHostName.range(of: "http://") {
            newHostName.removeSubrange(range)
        }
        
        if let range = newHostName.range(of: "https://") {
            newHostName.removeSubrange(range)
        }
        return newHostName
    }
}
