//
//  LMConstants.swift
//  mindLAMP Consortium
//
//  Created by Zco Engineer on 18/03/20.
//

import Foundation
import UIKit

struct CurrentDevice {
    static let name = UIDevice.current.name
    static let model = UIDevice.current.model
    static let osVersion = UIDevice.current.systemVersion
    static let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
}

struct Logs {
    struct URLParams {
        static let origin = "digital.lamp.app.ios"
    }
    
    struct Directory {
        static let logs = "Logs"
    }
    
    struct Messages { }
}

extension Logs.Messages {
    //static let accelerometer_null = "Aware error NULL : Accelerometer data does not exist."
    //static let gyroscope_null = "Aware error NULL : Gyroscope data does not exist."
    //static let magnetometer_null = "Aware error NULL : Magnetometer data does not exist."
    //static let rotation_null = "Aware error NULL : Rotation data does not exist."
    //static let gravity_null = "Aware error NULL : Gravity data does not exist."
    //static let location_null = "Aware error NULL : Location data does not exist."
    //static let screen_state_null = "Aware error NULL : ScreenState data does not exist."
    //static let wifi_null = "Aware error NULL : Wifi data does not exist."
    //static let calls_null = "Aware error NULL : Calls data does not exist."
    //static let pedometer_steps_null = "Aware error NULL : Pedometer Steps data does not exist."
    //static let pedometer_flights_null = "Aware error NULL : Pedometer Flights data does not exist."
    //static let pedometer_distane_null = "Aware error NULL : Pedometer Distance data does not exist."

    //static let bluetooth_null = "Lamp error NULL : Bluetooth data does not exist."

    //static let sleep_null = "Lamp HealthKit error NULL : Sleep data does not exist."
    //static let heart_rate_null = "Lamp HealthKit error NULL : HeartRate data does not exist."
    //static let respiratory_rate_null = "Lamp HealthKit error NULL : RespiratoryRate data does not exist."
    //static let blood_pessure_null = "Lamp HealthKit error NULL : BloodPressure data does not exist."
    //static let workout_null = "Lamp HealthKit error NULL : Workout data does not exist."
    //static let quantityType_null = "Lamp HealthKit error NULL : %@ data does not exist."
    //static let height_null = "Lamp HealthKit error NULL : Height data does not exist."
    //static let hkquantity_null = "Lamp HealthKit error NULL : HKQuantity data does not exist."
    //static let hkcharacteristic_null = "Lamp HealthKit error NULL : HKCharacteristic data does not exist."
    static let hk_characteristicType_fetch_error = "Lamp HealthKit CharacteristicType: %@."
    static let hk_data_fetch_uniterror = "Lamp HealthKit error NULL : Unit could not be retrieved."
    static let hk_data_fetch_error = "Lamp HealthKit: Data could not be retrieved."
    
    static let battery_low = "Battery is low."
    static let app_crash = "The app has crashed."
    static let gps_off = "GPS is disabled."
    static let location_error = "GPS Failed: %@"
    
    static let network_error = "Network error."
}

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
