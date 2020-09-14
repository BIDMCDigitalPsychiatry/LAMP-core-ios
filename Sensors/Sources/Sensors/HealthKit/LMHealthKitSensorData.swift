//
//  LMHealthKitSensorData.swift
//  mindLAMP Consortium
//
//  Created by Zco Engineer on 13/03/20.
//

import Foundation
import HealthKit

public class LMHealthKitCharacteristicData: LampSensorCoreObject {
    
    public var device: [String: Any]?
    public var startDate: Double?
    public var endDate: Double?
    public var metadata: [String: Any]?
    public var type: String = ""  // eg: HKQuantityTypeIdentifier
    public var value: Double?  // e.g., 60
    public var valueText: String?  // e.g., 60
    public var unit: String? // e.g., count/min
    public var hkIdentifier: HKCharacteristicTypeIdentifier
    
    public init(hkIdentifier: HKCharacteristicTypeIdentifier) {
        self.hkIdentifier = hkIdentifier
    }
}

public class LMHealthKitQuantityData: LampSensorCoreObject {
    
    public var device: [String: Any]?
    public var startDate: Double?
    public var endDate: Double?
    public var metadata: [String: Any]?
    public var type: String = ""  // eg: HKQuantityTypeIdentifier
    public var value: Double?  // e.g., 60
    public var valueText: String?  // e.g., 60
    public var unit: String? // e.g., count/min
    public var hkIdentifier: HKQuantityTypeIdentifier
    
    public init(hkIdentifier: HKQuantityTypeIdentifier) {
        self.hkIdentifier = hkIdentifier
    }
}

public class LMHealthKitCategoryData: LampSensorCoreObject {
    
    public var device: [String: Any]?
    public var startDate: Double?
    public var endDate: Double?
    public var metadata: [String: Any]?
    public var type: String = ""  // eg: HKQuantityTypeIdentifier
    public var value: Double?  // e.g., 60
    public var valueText: String?  // e.g., 60
    public var unit: String? // e.g., count/min
    public var hkIdentifier: HKCategoryTypeIdentifier
    
    public init(hkIdentifier: HKCategoryTypeIdentifier) {
        self.hkIdentifier = hkIdentifier
    }
}

public class LMHealthKitWorkoutData: LampSensorCoreObject {
    
    public var device: [String: Any]?
    public var startDate: Double?
    public var endDate: Double?
    public var metadata: [String: Any]?
    public var type: String = ""  // eg: HKQuantityTypeIdentifier
    public var value: Double?  // e.g., 60
    public var valueText: String?  // e.g., 60
    public var unit: String? // e.g., count/min

}
