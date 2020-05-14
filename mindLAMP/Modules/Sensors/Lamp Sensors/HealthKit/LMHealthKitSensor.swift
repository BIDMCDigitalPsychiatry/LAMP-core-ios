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
    public var healthStore : HKHealthStore
    public var fetchLimit = 100

    //HKQuantityData
    private var arrQuantityData = [LMHealthKitSensorData]()
    //HKCategoryData
    private var arrCategoryData = [LMHealthKitSensorData]()
    //HKWorkoutData
    private var arrWorkoutData = [LMHealthKitSensorData]()

    override init() {
        healthStore = HKHealthStore()
        super.init()
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

        let dataTypes = Set(lampHealthKitTypes())
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            if let observer = self.observer {
                observer.onHKAuthorizationStatusChanged(success: success, error: error)
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
        //adding other types
        if let bodyMassIndex = HKQuantityType.quantityType(forIdentifier:.bodyMassIndex) {
            arrTypes.append(bodyMassIndex)
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
        
        let quantityTypes = lampHKQuantityTypes()
        for type in quantityTypes {
            healthKitData(for: type, from: lastRecordedDate(for: type))
        }
        //
        
        let categoryTypes = lampHKCategoryTypes()
        for type in categoryTypes {
            healthKitData(for: type, from: lastRecordedDate(for: type))
        }
        
        let workoutType = HKWorkoutType.workoutType()
        healthKitData(for: workoutType, from: lastRecordedDate(for: workoutType))
    }
    
//    private func unit(for type: HKSampleType) -> HKUnit {
        
//        switch type.identifier {
//        case HKIdentifiers.bloodpressure_systolic.rawValue, HKIdentifiers.bloodpressure_diastolic.rawValue:
//            return .millimeterOfMercury()
//        case HKIdentifiers.heart_rate.rawValue, HKIdentifiers.respiratory_rate.rawValue:
//            return HKUnit.count().unitDivided(by: .minute())
//        case HKIdentifiers.height.rawValue:
//            return .meterUnit(with: .centi)
//        case HKIdentifiers.weight.rawValue:
//            return .gramUnit(with: .kilo)
//        default:
//            return HKUnit.count()
//        }
//    }
    
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
        healthStore.execute(quantityQuery)
    }
        
    
    private func saveQuantityData(_ samples: [HKQuantitySample], for type: HKSampleType) {
        
        var arrData = [LMHealthKitSensorData]()
        for sample in samples {
            let data = LMHealthKitSensorData()
            // device info
            if let device = sample.device {
                let json = device.toDictionary()
                data.device = json
            }
            let queryGroup = DispatchGroup()
            queryGroup.enter()
            var errorUnit: Error?
            healthStore.preferredUnits(for: [sample.quantityType]) { (dict, err) in
                if let unit = dict[sample.quantityType] {
                    data.value     = sample.quantity.doubleValue(for: unit)
                    data.unit      = unit.unitString
                } else {
                    errorUnit = err
                }
                queryGroup.leave()
            }
            if let err = errorUnit {
                LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.hk_data_fetch_uniterror + err.localizedDescription)
                continue
            }
            data.type      = sample.quantityType.identifier
            data.startDate = sample.startDate.timeInMilliSeconds
            data.endDate   = sample.endDate.timeInMilliSeconds
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
            data.type = sample.categoryType.identifier
            let typeIdentifier = HKCategoryTypeIdentifier(rawValue: sample.categoryType.identifier)
            switch typeIdentifier {
            case .sleepAnalysis:
                data.value = Double(sample.value)
                if let sleepAnalysis = HKCategoryValueSleepAnalysis(rawValue: sample.value) {
                    switch sleepAnalysis {
                    case .inBed:
                        printDebug("In Bed")
                    case .asleep:
                        printDebug("In Sleep")
                    case .awake:
                        printDebug("In Awake")
                    @unknown default:
                        ()
                    }
                }
            default:
                data.value = Double(sample.value)
            }
            data.startDate = sample.startDate.timeInMilliSeconds
            data.endDate   = sample.endDate.timeInMilliSeconds
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
            data.startDate = sample.startDate.timeInMilliSeconds
            data.endDate   = sample.endDate.timeInMilliSeconds
            if let meta = sample.metadata {
                data.metadata = meta
            }
            arrData.append(data)
        }
        arrWorkoutData.append(contentsOf: arrData)
    }
}
