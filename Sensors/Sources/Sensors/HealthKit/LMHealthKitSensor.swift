//
//  LMHealthKitSensor.swift
//  mindLAMP Consortium
//
//  Created by Zco Engineer on 13/03/20.
//

import Foundation
import HealthKit

public protocol LMHealthKitSensorObserver: class {
    func onHKAuthorizationStatusChanged(success: Bool, error: Error?)
    func onHKDataFetch(for type: String, error: Error?)
}

public class LMHealthKitSensor {
    
    // MARK: - VARIABLES
    
    public weak var observer: LMHealthKitSensorObserver?
    public var healthStore : HKHealthStore
    public var fetchLimit = 100
    
    //HKQuantityData
    private var arrQuantityData = [LMHealthKitQuantityData]()
    //HKCategoryData
    private var arrCategoryData = [LMHealthKitCategoryData]()
    //HK Characteristic data
    private var arrCharacteristicData = [LMHealthKitCharacteristicData]()
    //HKWorkoutData
    private var arrWorkoutData = [LMHealthKitWorkoutData]()
    
    public init() {
        healthStore = HKHealthStore()
        //super.init()
    }
    
    public func start() {
        requestAuthorizationForLampHKTypes()
    }
    
    public func stop() {}
    
    //when ever add new data type, then handle the same in fetchHealthKitQuantityData(), extension HKQuantityTypeIdentifier: LampDataKeysProtocol
    public lazy var healthQuantityTypes: [HKSampleType] = {
        
        var quantityTypes = [HKSampleType]()
        var identifiers: [HKQuantityTypeIdentifier] = [.heartRate, .bodyMass, .height, .bloodPressureDiastolic, .bloodPressureSystolic, .respiratoryRate, .bodyMassIndex, .bodyFatPercentage, .leanBodyMass, .waistCircumference]
        identifiers.append(contentsOf: [.stepCount, .distanceWalkingRunning, .distanceCycling, .distanceWheelchair, .basalEnergyBurned, .activeEnergyBurned, .flightsClimbed, .nikeFuel, .appleExerciseTime, .pushCount, .distanceSwimming, .swimmingStrokeCount, .vo2Max, .distanceDownhillSnowSports])
        identifiers.append(contentsOf: [.bodyTemperature, .basalBodyTemperature, .restingHeartRate, .walkingHeartRateAverage, .heartRateVariabilitySDNN, .oxygenSaturation, .peripheralPerfusionIndex, .bloodGlucose, .numberOfTimesFallen, .electrodermalActivity, .inhalerUsage, .insulinDelivery, .bloodAlcoholContent, .forcedVitalCapacity, .forcedExpiratoryVolume1, .peakExpiratoryFlowRate])
        identifiers.append(contentsOf: [.dietaryFatTotal, .dietaryFatPolyunsaturated, .dietaryFatMonounsaturated, .dietaryFatSaturated, .dietaryCholesterol, .dietarySodium, .dietaryCarbohydrates, .dietaryFiber, .dietarySugar, .dietaryEnergyConsumed, .dietaryProtein, .dietaryVitaminA, .dietaryVitaminB6, .dietaryVitaminB12, .dietaryVitaminC, .dietaryVitaminD, .dietaryVitaminE, .dietaryVitaminK, .dietaryCalcium, .dietaryIron, .dietaryThiamin, .dietaryRiboflavin, .dietaryNiacin, .dietaryFolate, .dietaryBiotin, .dietaryPantothenicAcid, .dietaryPhosphorus, .dietaryIodine, .dietaryMagnesium, .dietaryZinc, .dietarySelenium, .dietaryCopper, .dietaryManganese, .dietaryChromium, .dietaryMolybdenum, .dietaryChloride, .dietaryPotassium, .dietaryCaffeine, .dietaryWater, .uvExposure])
        if #available(iOS 13.0, *) {
            identifiers.append(.appleStandTime)
            identifiers.append(.environmentalAudioExposure)
            identifiers.append(.headphoneAudioExposure)
            
        } else {
            // Fallback on earlier versions
        }
        for identifier in identifiers {
            if let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) {
                quantityTypes.append(quantityType)
            }
        }
        return quantityTypes
    }()
    
    public lazy var healthCategoryTypes: [HKSampleType] = {
        var arrTypes = [HKSampleType]()
        var identifiers: [HKCategoryTypeIdentifier] = [.sleepAnalysis, .appleStandHour, .cervicalMucusQuality, .ovulationTestResult, .menstrualFlow, .intermenstrualBleeding, .sexualActivity, .mindfulSession]
        if #available(iOS 13.0, *) {
            identifiers.append(contentsOf: [.highHeartRateEvent, .lowHeartRateEvent, .irregularHeartRhythmEvent, .audioExposureEvent, .toothbrushingEvent])
        }
        for identifier in identifiers {
            if let quantityType = HKCategoryType.categoryType(forIdentifier: identifier) {
                arrTypes.append(quantityType)
            }
        }
        return arrTypes
    }()
    
    lazy var healthCharacteristicTypes: [HKObjectType] = {
        var characteristicTypes = [HKObjectType]()
        var identifiers: [HKCharacteristicTypeIdentifier] = [HKCharacteristicTypeIdentifier.biologicalSex, HKCharacteristicTypeIdentifier.bloodType, HKCharacteristicTypeIdentifier.dateOfBirth, HKCharacteristicTypeIdentifier.fitzpatrickSkinType, HKCharacteristicTypeIdentifier.wheelchairUse]
        for identifier in identifiers {
            if let coreRelationType = HKCorrelationType.characteristicType(forIdentifier: identifier) {
                characteristicTypes.append(coreRelationType)
            }
        }
        return characteristicTypes
    }()
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
    
    private func lampHealthKitTypes() -> [HKObjectType] {
        var arrSampleTypes = [HKObjectType]()
        
        arrSampleTypes.append(contentsOf: healthQuantityTypes)
        arrSampleTypes.append(contentsOf: healthCategoryTypes)
        arrSampleTypes.append(contentsOf: healthCharacteristicTypes)
        let workout = HKWorkoutType.workoutType()
        arrSampleTypes.append(workout)
        
        return arrSampleTypes
    }
    
    private func clearDataArrays() {
        arrQuantityData.removeAll()
        arrCategoryData.removeAll()
        arrWorkoutData.removeAll()
        arrCharacteristicData.removeAll()
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
    
//    func saveLastRecordedAnchor(_ anchor: Int, for type: HKSampleType) {
//        let userDefaults = UserDefaults.standard
//        let key = String(format: "LMHealthKit_%@_anchor", type.identifier)
//        userDefaults.set(anchor, forKey: key)
//        userDefaults.synchronize()
//    }
//    
//    func lastRecordedAnchor(for type: HKSampleType) -> Int? {
//        let userDefaults = UserDefaults.standard
//        let key = String(format: "LMHealthKit_%@_anchor", type.identifier)
//        let date = userDefaults.object(forKey: key) as? Int
//        return date
//    }
}

extension LMHealthKitSensor {
    
    public func latestQuantityData() -> [LMHealthKitQuantityData]? {
        return arrQuantityData
    }
    
    public func latestCategoryData() -> [LMHealthKitCategoryData]? {
        return arrCategoryData
    }
    
    public func latestCharacteristicData() -> [LMHealthKitCharacteristicData]? {
        return arrCharacteristicData
    }
    
    public func latestWorkoutData() -> [LMHealthKitWorkoutData]? {
        return arrWorkoutData
    }
    
    public func fetchHealthData() {
        clearDataArrays()
        
        let quantityTypes = healthQuantityTypes
        for type in quantityTypes {
            healthKitData(for: type, from: lastRecordedDate(for: type))
        }
        //
        
        let categoryTypes = healthCategoryTypes
        for type in categoryTypes {
            healthKitData(for: type, from: lastRecordedDate(for: type))
        }
        
        loadCharachteristicData()
        
        let workoutType = HKWorkoutType.workoutType()
        healthKitData(for: workoutType, from: lastRecordedDate(for: workoutType))
    }
    
    func loadCharachteristicData() {
        
        var arrData = [LMHealthKitCharacteristicData]()
        
        do {
            //1. This method throws an error if these data are not available.
            let birthdayComponents =  try healthStore.dateOfBirthComponents()
            
            //2. Use Calendar to calculate age.
            let today = Date()
            let calendar = Calendar.current
            let todayDateComponents = calendar.dateComponents([.year],
                                                              from: today)
            let thisYear = todayDateComponents.year!
            let age = thisYear - birthdayComponents.year!
            
            if let date = Calendar.current.date(from: birthdayComponents) {
                let data = LMHealthKitCharacteristicData(hkIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)
                data.valueText = "\(age)"
                data.value = date.timeInMilliSeconds
                arrData.append(data)
            }

        } catch let error {
            print("error = \(error.localizedDescription)")
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.hk_characteristicType_fetch_error + error.localizedDescription)
        }
        do {
            let biologicalSex =       try healthStore.biologicalSex()
            let unwrappedBiologicalSex = biologicalSex.biologicalSex
            
            let data = LMHealthKitCharacteristicData(hkIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)
            data.value = Double(unwrappedBiologicalSex.rawValue)
            data.valueText = unwrappedBiologicalSex.stringValue
            arrData.append(data)
        } catch let error {
            print("error = \(error.localizedDescription)")
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.hk_characteristicType_fetch_error + error.localizedDescription)
        }
        
        do {
            let bloodType =           try healthStore.bloodType()
            let unwrappedBloodType = bloodType.bloodType
            
            let data = LMHealthKitCharacteristicData(hkIdentifier: HKCharacteristicTypeIdentifier.bloodType)
            data.value = Double(unwrappedBloodType.rawValue)
            data.valueText = unwrappedBloodType.stringValue
            arrData.append(data)
        } catch let error {
            print("error = \(error.localizedDescription)")
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.hk_characteristicType_fetch_error + error.localizedDescription)
        }
        
        do {
            let wheelcharirUse =      try healthStore.wheelchairUse()
            let unwrappedWheelChairUse = wheelcharirUse.wheelchairUse
            
            let data = LMHealthKitCharacteristicData(hkIdentifier: HKCharacteristicTypeIdentifier.wheelchairUse)
            data.value = Double(unwrappedWheelChairUse.rawValue)
            data.valueText = unwrappedWheelChairUse.stringValue
            arrData.append(data)
        } catch let error {
            print("error = \(error.localizedDescription)")
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.hk_characteristicType_fetch_error + error.localizedDescription)
        }
        do {
            let skinType =            try healthStore.fitzpatrickSkinType()
            let unWrappedSkinType = skinType.skinType
            
            let data = LMHealthKitCharacteristicData(hkIdentifier: HKCharacteristicTypeIdentifier.fitzpatrickSkinType)
            data.value = Double(unWrappedSkinType.rawValue)
            data.valueText = unWrappedSkinType.stringValue
            arrData.append(data)
        } catch let error {
            print("error = \(error.localizedDescription)")
            //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.hk_characteristicType_fetch_error + error.localizedDescription)
        }
        arrCharacteristicData.append(contentsOf: arrData)
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
            
            if error != nil {
                self.observer?.onHKDataFetch(for: type.identifier, error: error)
                return
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
        
        var arrData = [LMHealthKitQuantityData]()
        for sample in samples {
            let typeIdentifier = HKQuantityTypeIdentifier(rawValue: sample.quantityType.identifier)
            let data = LMHealthKitQuantityData(hkIdentifier: typeIdentifier)
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
            if nil != errorUnit {
                //LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.hk_data_fetch_uniterror + err.localizedDescription)
                continue
            }
            
            data.type      = sample.quantityType.identifier
            data.startDate = sample.startDate.timeInMilliSeconds
            data.endDate   = sample.endDate.timeInMilliSeconds
            data.hkIdentifier = typeIdentifier
            if let meta = sample.metadata {
                data.metadata = meta
            }
            arrData.append(data)
        }
        if healthQuantityTypes.contains(type) {
            arrQuantityData.append(contentsOf: arrData)
        }
    }
    
    private func saveCategoryData(_ samples: [HKCategorySample], for type: HKSampleType) {
        
        var arrData = [LMHealthKitCategoryData]()
        for sample in samples {
            let typeIdentifier = HKCategoryTypeIdentifier(rawValue: sample.categoryType.identifier)
            let data = LMHealthKitCategoryData(hkIdentifier: typeIdentifier)
            // device info
            if let device = sample.device {
                let json = device.toDictionary()
                data.device = json
            }
            data.type = sample.categoryType.identifier
            
            switch typeIdentifier {
            case .sleepAnalysis:
                data.value = Double(sample.value)
                if let sleepAnalysis = HKCategoryValueSleepAnalysis(rawValue: sample.value) {
                    data.valueText = sleepAnalysis.stringValue
                }
            case .appleStandHour:
                data.value = Double(sample.value)
                if let standHour = HKCategoryValueAppleStandHour(rawValue: sample.value) {
                    data.valueText = standHour.stringValue
                }
            case .cervicalMucusQuality:
                data.value = Double(sample.value)
                if let quality = HKCategoryValueCervicalMucusQuality(rawValue: sample.value) {
                    data.valueText = quality.stringValue
                }
            case .ovulationTestResult:
                data.value = Double(sample.value)
                if let obj = HKCategoryValueOvulationTestResult(rawValue: sample.value) {
                    data.valueText = obj.stringValue
                }
            case .menstrualFlow:
                data.value = Double(sample.value)
                if let obj = HKCategoryValueMenstrualFlow(rawValue: sample.value) {
                    data.valueText = obj.stringValue
                }
            default:
                data.value = Double(sample.value)
            }
            
            if #available(iOS 13.0, *) {
                if typeIdentifier == .audioExposureEvent {
                    data.value = Double(sample.value)
                    if let obj = HKCategoryValueAudioExposureEvent(rawValue: sample.value) {
                        data.valueText = obj.stringValue
                    }
                }
            }
            
            data.startDate = sample.startDate.timeInMilliSeconds
            data.endDate   = sample.endDate.timeInMilliSeconds
            data.hkIdentifier = typeIdentifier
            if let meta = sample.metadata {
                data.metadata = meta
            }
            arrData.append(data)
        }
        if healthCategoryTypes.contains(type) {
            arrCategoryData.append(contentsOf: arrData)
        }
    }
    
    private func saveWorkoutData(_ samples: [HKWorkout], for type: HKSampleType) {
        var arrData = [LMHealthKitWorkoutData]()
        for sample in samples {
            
            let data = LMHealthKitWorkoutData()
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
