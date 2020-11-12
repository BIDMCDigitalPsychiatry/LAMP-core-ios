//
//  LMConstants.swift
//  mindLAMP Consortium
//
//  Created by Zco Engineer on 18/03/20.
//

import Foundation
import UIKit

struct Logs {
    struct URLParams {
        static let origin = "digital.lamp.app.ios"
    }
    
    struct Directory {
        static let logs = "Logs"
        static let sensorlogs = "SensorLogs"
    }
    
    struct Messages { }
}

extension Logs.Messages {
    static let hk_data_fetch_error = "Lamp HealthKit: Data could not be retrieved."
    
    static let battery_low = "Battery is low."
    static let gps_off = "GPS is disabled."
    static let location_error = "GPS Failed: %@"
    
    static let network_error = "Network error."
}

