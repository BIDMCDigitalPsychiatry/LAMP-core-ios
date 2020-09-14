//
//  LMCommon.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engineer on 14/01/20.
//

import Foundation
import HealthKit

extension HKQuantityTypeIdentifier: LampDataKeysProtocol {
    
    public var lampIdentifier: String {
        
        if #available(iOS 13.0, *) {
            if self == .appleStandTime {
                return "lamp.appleStandTime"
            }
            else if self == .environmentalAudioExposure {
                return "lamp.environmentalAudioExposure"
            }
            else if self == .headphoneAudioExposure {
                return "lamp.headphoneAudioExposure"
            }
        }
        
        switch self {
        case .stepCount:
            return "lamp.step_count"
        case .bloodPressureSystolic:
            return "lamp.blood_pressure"
        case .bloodPressureDiastolic:
            return "lamp.blood_pressure"
        case .heartRate:
            return "lamp.heart_rate"
        case .height:
            return "lamp.height"
        case .respiratoryRate:
            return "lamp.respiratory_rate"
        case .bodyMass:
            return "lamp.weight"
        case .bodyMassIndex:
            return "lamp.bmi"
        case .bodyFatPercentage:
            return "lamp.body_fat_percentage"
        case .leanBodyMass:
            return "lamp.leanBodyMass"
        case .waistCircumference:
            return "lamp.waistCircumference"
        case .distanceWalkingRunning:
            return "lamp.distanceWalkingRunning"
        case .distanceCycling:
            return "lamp.distanceCycling"
        case .distanceWheelchair:
            return "lamp.distanceWheelchair"
        case .basalEnergyBurned:
            return "lamp.basalEnergyBurned"
        case .activeEnergyBurned:
            return "lamp.activeEnergyBurned"
        case .flightsClimbed:
            return "lamp.flightsClimbed"
        case .nikeFuel:
            return "lamp.nikeFuel"
        case .appleExerciseTime:
            return "lamp.appleExerciseTime"
        case .pushCount:
            return "lamp.pushCount"
        case .distanceSwimming:
            return "lamp.distanceSwimming"
        case .swimmingStrokeCount:
            return "lamp.swimmingStrokeCount"
        case .vo2Max:
            return "lamp.vo2Max"
        case .distanceDownhillSnowSports:
            return "lamp.distanceDownhillSnowSports"
            
        case .bodyTemperature:
            return "lamp.body_temperature"
        case .basalBodyTemperature:
            return "lamp.basalBodyTemperature"
        case .restingHeartRate:
            return "lamp.restingHeartRate"
        case .walkingHeartRateAverage:
            return "lamp.walkingHeartRateAverage"
        case .heartRateVariabilitySDNN:
            return "lamp.heartRateVariabilitySDNN"
        case .oxygenSaturation:
            return "lamp.oxygenSaturation"
        case .peripheralPerfusionIndex:
            return "lamp.peripheralPerfusionIndex"
        case .bloodGlucose:
            return "lamp.blood_glucose"
        case .numberOfTimesFallen:
            return "lamp.numberOfTimesFallen"
        case .electrodermalActivity:
            return "lamp.electrodermalActivity"
        case .inhalerUsage:
            return "lamp.inhalerUsage"
        case .insulinDelivery:
            return "lamp.insulinDelivery"
        case .bloodAlcoholContent:
            return "lamp.bloodAlcoholContent"
        case .forcedVitalCapacity:
            return "lamp.forcedVitalCapacity"
        case .forcedExpiratoryVolume1:
            return "lamp.forcedExpiratoryVolume1"
        case .peakExpiratoryFlowRate:
            return "lamp.peakExpiratoryFlowRate"
            
        case .dietaryFatTotal:
            return "lamp.dietaryFatTotal"
        case .dietaryFatPolyunsaturated:
            return "lamp.dietaryFatPolyunsaturated"
        case .dietaryFatMonounsaturated:
            return "lamp.dietaryFatMonounsaturated"
        case .dietaryFatSaturated:
            return "lamp.dietaryFatSaturated"
        case .dietaryCholesterol:
            return "lamp.dietaryCholesterol"
        case .dietarySodium:
            return "lamp.dietarySodium"
        case .dietaryCarbohydrates:
            return "lamp.dietaryCarbohydrates"
        case .dietaryFiber:
            return "lamp.dietaryFiber"
        case .dietarySugar:
            return "lamp.dietarySugar"
        case .dietaryEnergyConsumed:
            return "lamp.dietaryEnergyConsumed"
        case .dietaryProtein:
            return "lamp.dietaryProtein"
        case .dietaryVitaminA:
            return "lamp.dietaryVitaminA"
        case .dietaryVitaminB6:
            return "lamp.dietaryVitaminB6"
        case .dietaryVitaminB12:
            return "lamp.dietaryVitaminB12"
        case .dietaryVitaminC:
            return "lamp.dietaryVitaminC"
        case .dietaryVitaminD:
            return "lamp.dietaryVitaminD"
        case .dietaryVitaminE:
            return "lamp.dietaryVitaminE"
        case .dietaryVitaminK:
            return "lamp.dietaryVitaminK"
        case .dietaryCalcium:
            return "lamp.dietaryCalcium"
        case .dietaryIron:
            return "lamp.dietaryIron"
        case .dietaryThiamin:
            return "lamp.dietaryThiamin"
        case .dietaryRiboflavin:
            return "lamp.dietaryRiboflavin"
        case .dietaryNiacin:
            return "lamp.dietaryNiacin"
        case .dietaryFolate:
            return "lamp.dietaryFolate"
        case .dietaryBiotin:
            return "lamp.dietaryBiotin"
        case .dietaryPantothenicAcid:
            return "lamp.dietaryPantothenicAcid"
        case .dietaryPhosphorus:
            return "lamp.dietaryPhosphorus"
        case .dietaryIodine:
            return "lamp.dietaryIodine"
        case .dietaryMagnesium:
            return "lamp.dietaryMagnesium"
        case .dietaryZinc:
            return "lamp.dietaryZinc"
        case .dietarySelenium:
            return "lamp.dietarySelenium"
        case .dietaryCopper:
            return "lamp.dietaryCopper"
        case .dietaryManganese:
            return "lamp.dietaryManganese"
        case .dietaryChromium:
            return "lamp.dietaryChromium"
        case .dietaryMolybdenum:
            return "lamp.dietaryMolybdenum"
        case .dietaryChloride:
            return "lamp.dietaryChloride"
        case .dietaryPotassium:
            return "lamp.dietaryPotassium"
        case .dietaryCaffeine:
            return "lamp.dietaryCaffeine"
        case .dietaryWater:
            return "lamp.dietaryWater"
        case .dietaryCopper:
            return "lamp.uvExposure"
            
        default:
            return "lamp.\(self.rawValue)"
        }
    }
}

extension HKCategoryTypeIdentifier: LampDataKeysProtocol {
    
    public var lampIdentifier: String {
        
        if #available(iOS 13.0, *) {
            switch self {
            case .sleepAnalysis:
                return "lamp.sleep"
            case .appleStandHour:
                return "lamp.appleStandHour"
            case .cervicalMucusQuality:
                return "lamp.cervicalMucusQuality"
            case .ovulationTestResult:
                return "lamp.ovulationTestResult"
            case .menstrualFlow:
                return "lamp.menstrualFlow"
            case .intermenstrualBleeding:
                return "lamp.intermenstrualBleeding"
            case .sexualActivity:
                return "lamp.sexualActivity"
            case .mindfulSession:
                return "lamp.mindfulSession"
            case .highHeartRateEvent:
                return "lamp.highHeartRateEvent"
            case .lowHeartRateEvent:
                return "lamp.lowHeartRateEvent"
            case .irregularHeartRhythmEvent:
                return "lamp.irregularHeartRhythmEvent"
            case .audioExposureEvent:
                return "lamp.audioExposureEvent"
            case .toothbrushingEvent:
                return "lamp.toothbrushingEvent"
            default:
                return "lamp.\(self.rawValue)"
            }
        } else {
            if #available(iOS 12.2, *) {
                switch self {
                case .sleepAnalysis:
                    return "lamp.sleep"
                case .appleStandHour:
                    return "lamp.appleStandHour"
                case .cervicalMucusQuality:
                    return "lamp.cervicalMucusQuality"
                case .ovulationTestResult:
                    return "lamp.ovulationTestResult"
                case .menstrualFlow:
                    return "lamp.menstrualFlow"
                case .intermenstrualBleeding:
                    return "lamp.intermenstrualBleeding"
                case .sexualActivity:
                    return "lamp.sexualActivity"
                case .mindfulSession:
                    return "lamp.mindfulSession"
                case .highHeartRateEvent:
                    return "lamp.highHeartRateEvent"
                case .lowHeartRateEvent:
                    return "lamp.lowHeartRateEvent"
                case .irregularHeartRhythmEvent:
                    return "lamp.irregularHeartRhythmEvent"
                default:
                    return "lamp.\(self.rawValue)"
                }
            } else {
                switch self {
                case .sleepAnalysis:
                    return "lamp.sleep"
                case .appleStandHour:
                    return "lamp.appleStandHour"
                case .cervicalMucusQuality:
                    return "lamp.cervicalMucusQuality"
                case .ovulationTestResult:
                    return "lamp.ovulationTestResult"
                case .menstrualFlow:
                    return "lamp.menstrualFlow"
                case .intermenstrualBleeding:
                    return "lamp.intermenstrualBleeding"
                case .sexualActivity:
                    return "lamp.sexualActivity"
                case .mindfulSession:
                    return "lamp.mindfulSession"
                default:
                    return "lamp.\(self.rawValue)"
                }
            }
        }
        
        
        
        
    }
}

extension HKCharacteristicTypeIdentifier: LampDataKeysProtocol {
    
    public var lampIdentifier: String {
        switch self {
        case .biologicalSex:
            return "lamp.biologicalSex"
        case .bloodType:
            return "lamp.bloodType"
        case .dateOfBirth:
            return "lamp.dob"
        case .fitzpatrickSkinType:
            return "lamp.skinType"
        case .wheelchairUse:
            return "lamp.wheelchairUse"
            
        default:
            return "lamp.\(self.rawValue)"
        }
    }
}
