//
//  HKDevice+Extension.swift
//  mindLAMP
//
//  Created by Zco Engineer on 17/03/20.
//

import Foundation
import HealthKit

extension HKDevice {
    public func toDictionary() -> [String: Any] {
        // name:Apple Watch, manufacturer:Apple, model:Watch, hardware:Watch2,4, software:5.1.1
        var dict = [String: Any]()
        if let uwName = name { dict["name"] = uwName }
        if let uwManufacturer = manufacturer { dict["manufacturer"] = uwManufacturer }
        if let uwModel = model { dict["model"] = uwModel }
        if let uwHardware = hardwareVersion { dict["hardware"] = uwHardware }
        if let uwSoftware = softwareVersion { dict["software"] = uwSoftware }
        return dict
    }
}
