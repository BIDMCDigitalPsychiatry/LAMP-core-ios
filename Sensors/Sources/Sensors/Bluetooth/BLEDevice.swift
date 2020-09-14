//
//  File.swift
//  
//
//  Created by Zco Engineer on 27/07/20.
//

import Foundation

struct BLEDevice {
    struct ServiceUuid {
        /// BLE common service UUIDs
        static let BATTERY_SERVICE           = "180F"
        static let BODY_COMPOSITION_SERIVCE  = "181B"
        static let CURRENT_TIME_SERVICE      = "1805"
        static let DEVICE_INFORMATION        = "180A"
        static let ENVIRONMENTAL_SENSING     = "181A"
        static let GENERIC_ACCESS            = "1800"
        static let GENERIC_ATTRIBUTE         = "1801"
        static let MEASUREMENT               = "2A37"
        static let BODY_LOCATION             = "2A38"
        static let MANUFACTURER_NAME         = "2A29"
        static let HEART_RATE_UUID           = "180D"
        static let HTTP_PROXY_UUID           = "1823"
        static let HUMAN_INTERFACE_DEVICE    = "1812"
        static let INDOOR_POSITIONING        = "1820"
        static let LOCATION_NAVIGATION       = "1819"
        static let PHONE_ALERT_STATUS        = "180E"
        static let REFERENCE_TIME            = "1806"
        static let SCAN_PARAMETERS           = "1813"
        static let TRANSPORT_DISCOVERY       = "1824"
        static let USER_DATA                 = "181C"
        static let UNDEFINED                 = "AA80"
    }
}
