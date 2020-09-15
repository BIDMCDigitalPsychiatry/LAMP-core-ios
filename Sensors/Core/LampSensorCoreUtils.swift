//
//  LampSensorCoreUtils.swift
//  mindLAMP Consortium
//
//  Created by ZCO Engineer on 13/01/20.
//

import Foundation

public class LampSensorCoreUtils {

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
