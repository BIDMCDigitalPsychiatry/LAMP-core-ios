//
//  LMHealthKitSensor.swift
//  mindLAMP
//
//  Created by Zco Engineer on 13/03/20.
//

import Foundation
import HealthKit

protocol LMHealthKitSensorObserver: class {
    func onHKAuthorizationStatusChanged(success: Bool, error: Error?)
    func onHKDataFetch(for type: String, error: Error?)
}

class LMHealthKitSensor: NSObject {
            
    // MARK: - VARIABLES

    weak var observer: LMHealthKitSensorObserver?
    public var healthStore : HKHealthStore?
    public var fetchLimit = 100

    //HKQuantityData
    private var arrQuantityData = [LMHealthKitSensorData]()
    //HKCategoryData
    private var arrCategoryData = [LMHealthKitSensorData]()
    //HKWorkoutData
    private var arrWorkoutData = [LMHealthKitSensorData]()

    override init() {
        super.init()
        
        healthStore = HKHealthStore()
    }
    
     func start() {
        requestAuthorizationForLampHKTypes()
    }
    
    func stop() {}
}

extension LMHealthKitSensor {
    
    private func requestAuthorizationForLampHKTypes() {
        
        guard HKHealthStore.isHealthDataAvailable() == true else {
            return
        }

        var dataTypes = Set<HKSampleType>()
        for type in lampHealthKitTypes() {
            dataTypes.insert(type)
        }
        
        if let healthKit = healthStore {
            healthKit.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
                if let observer = self.observer {
                    observer.onHKAuthorizationStatusChanged(success: success, error: error)
                }
            }
        }
    }
    
    private func lampHealthKitTypes() -> [HKSampleType] {
        var arrSampleTypes = [HKSampleType]()
        
        arrSampleTypes.append(contentsOf: lampHKQuantityTypes())
        arrSampleTypes.append(contentsOf: lampHKCategoryTypes())
        
        let workout = HKWorkoutType.workoutType()
        arrSampleTypes.append(workout)
        
        return arrSampleTypes
    }
    
    private func lampHKQuantityTypes() -> [HKSampleType] {
        
        var arrTypes = [HKSampleType]()
        if let heartRate = HKQuantityType.quantityType(forIdentifier:.heartRate) {
            arrTypes.append(heartRate)
        }
        if let bodyMass = HKQuantityType.quantityType(forIdentifier:.bodyMass) {
            arrTypes.append(bodyMass)
        }
        if let height = HKQuantityType.quantityType(forIdentifier:.height) {
            arrTypes.append(height)
        }
        if let bloodpressure_diastolic = HKQuantityType.quantityType(forIdentifier:.bloodPressureDiastolic) {
            arrTypes.append(bloodpressure_diastolic)
        }
        if let bloodpressure_systolic = HKQuantityType.quantityType(forIdentifier:.bloodPressureSystolic) {
            arrTypes.append(bloodpressure_systolic)
        }
        if let respiratory_rate = HKQuantityType.quantityType(forIdentifier:.respiratoryRate) {
            arrTypes.append(respiratory_rate)
        }
        return arrTypes
    }
    
    private func lampHKCategoryTypes() -> [HKSampleType] {
        var arrTypes = [HKSampleType]()
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            arrTypes.append(sleep)
        }
        return arrTypes
    }
    
    private func clearDataArrays() {
        arrQuantityData.removeAll()
        arrCategoryData.removeAll()
        arrWorkoutData.removeAll()
    }
}

extension LMHealthKitSensor {
    
    func saveLastRecordedDate(_ date: Date, for type: HKSampleType) {
        let userDefaults = UserDefaults.standard
        let key = String(format: "LMHealthKit_%@_timestamp", type.identifier)
        userDefaults.set(date, forKey: key)
        userDefaults.synchronize()
    }
    
    func lastRecordedDate(for type: HKSampleType) -> Date {
        let userDefaults = UserDefaults.standard
        let key = String(format: "LMHealthKit_%@_timestamp", type.identifier)
        let date = userDefaults.object(forKey: key) as? Date ?? Date()
        return date
    }
    
    func saveLastRecordedAnchor(_ anchor: Int, for type: HKSampleType) {
        let userDefaults = UserDefaults.standard
        let key = String(format: "LMHealthKit_%@_anchor", type.identifier)
        userDefaults.set(anchor, forKey: key)
        userDefaults.synchronize()
    }
    
    func lastRecordedAnchor(for type: HKSampleType) -> Int? {
        let userDefaults = UserDefaults.standard
        let key = String(format: "LMHealthKit_%@_anchor", type.identifier)
        let date = userDefaults.object(forKey: key) as? Int
        return date
    }
}

extension LMHealthKitSensor {
    
    public func latestQuantityData() -> [LMHealthKitSensorData]? {
        return arrQuantityData
    }
    
    public func latestCategoryData() -> [LMHealthKitSensorData]? {
        return arrCategoryData
    }
    
    public func latestWorkoutData() -> [LMHealthKitSensorData]? {
        return arrWorkoutData
    }
    
    public func fetchHealthData() {
        clearDataArrays()
        for type in lampHealthKitTypes() {
            healthKitData(for: type, from: lastRecordedDate(for: type))
        }
    }
    
    private func unit(for type: HKSampleType) -> HKUnit {
        switch type.identifier {
        case HKIdentifiers.bloodpressure_systolic.rawValue, HKIdentifiers.bloodpressure_diastolic.rawValue:
            return .millimeterOfMercury()
        case HKIdentifiers.heart_rate.rawValue, HKIdentifiers.respiratory_rate.rawValue:
            return HKUnit.count().unitDivided(by: .minute())
        case HKIdentifiers.height.rawValue:
            return .meterUnit(with: .centi)
        case HKIdentifiers.weight.rawValue:
            return .gramUnit(with: .kilo)
        default:
            return HKUnit.count()
        }
    }
    
    private func healthKitData(for type: HKSampleType, from start: Date?) {
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let quantityQuery = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, sampleObjects, error) in
            
            guard let type = query.objectType as? HKSampleType else { return }
            
            if error != nil, let observer = self.observer {
                observer.onHKDataFetch(for: type.identifier, error: error)
            }
            if let samples = sampleObjects as? [HKQuantitySample] {
                
                self.saveQuantityData(samples, for: type)
                let lastDate = samples.last?.endDate ?? Date()
                self.saveLastRecordedDate(lastDate, for: type)
            } else if let samples = sampleObjects as? [HKCategorySample] {
                
                self.saveCategoryData(samples, for: type)
                let lastDate = samples.last?.endDate ?? Date()
                self.saveLastRecordedDate(lastDate, for: type)
            } else if let samples = sampleObjects as? [HKWorkout] {
                
                self.saveWorkoutData(samples, for: type)
                let lastDate = samples.last?.endDate ?? Date()
                self.saveLastRecordedDate(lastDate, for: type)
            }
        }
        healthStore?.execute(quantityQuery)
    }
        
    
    private func saveQuantityData(_ samples: [HKQuantitySample], for type: HKSampleType) {
        
        var arrData = [LMHealthKitSensorData]()
        for sample in samples {
            let data = LMHealthKitSensorData()
            // device info
            if let device = sample.device{
                let json = device.toDictionary()
                data.device = json
            }
            let unit     = self.unit(for: type)
            data.type      = sample.quantityType.description
            data.value     = sample.quantity.doubleValue(for: unit)
            data.unit      = unit.unitString
            data.startDate = Int64(sample.startDate.timeIntervalSince1970 * 1000)
            data.endDate   = Int64(sample.endDate.timeIntervalSince1970 * 1000)
            if let meta = sample.metadata {
                data.metadata = meta
            }
            arrData.append(data)
        }
        if lampHKQuantityTypes().contains(type) {
            arrQuantityData.append(contentsOf: arrData)
        }
    }
    
    private func saveCategoryData(_ samples: [HKCategorySample], for type: HKSampleType) {
        
        var arrData = [LMHealthKitSensorData]()
        for sample in samples {
            let data = LMHealthKitSensorData()
            // device info
            if let device = sample.device{
                let json = device.toDictionary()
                data.device = json
            }
            data.type      = sample.categoryType.description
            data.value     = Double(sample.value)
            data.startDate = Int64(sample.startDate.timeIntervalSince1970 * 1000)
            data.endDate   = Int64(sample.endDate.timeIntervalSince1970 * 1000)
            if let meta = sample.metadata {
                data.metadata = meta
            }
            arrData.append(data)
        }
        if lampHKCategoryTypes().contains(type) {
            arrCategoryData.append(contentsOf: arrData)
        }
    }
    
    private func saveWorkoutData(_ samples: [HKWorkout], for type: HKSampleType) {
        var arrData = [LMHealthKitSensorData]()
        for sample in samples {
            
            let data = LMHealthKitSensorData()
            // device info
            if let device = sample.device{
                let json = device.toDictionary()
                data.device = json
            }
            data.type = sample.workoutActivityType.stringType
            data.value = sample.duration
            data.startDate = Int64(sample.startDate.timeIntervalSince1970 * 1000)
            data.endDate   = Int64(sample.endDate.timeIntervalSince1970 * 1000)
            if let meta = sample.metadata {
                data.metadata = meta
            }
            arrData.append(data)
        }
        arrWorkoutData.append(contentsOf: arrData)
    }
}
