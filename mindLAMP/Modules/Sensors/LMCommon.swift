//
//  LMCommon.swift
//  lampv2
//
//  Created by ZCo Engineer on 14/01/20.
//

import Foundation
import HealthKit

protocol LampDataKeysProtocol {
    var jsonKey: String {get}
}


//extension LampDataKeysProtocol {
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.singleValueContainer()
//        try container.encode(jsonKey)
//    }
//}


extension HKQuantityTypeIdentifier: LampDataKeysProtocol {
    
    var jsonKey: String {
        
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
    
    var jsonKey: String {
        
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
    
    var jsonKey: String {
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

enum SensorType: LampDataKeysProtocol {
    
    case lamp_accelerometer
    case lamp_accelerometer_motion
    case lamp_analytics
    case lamp_bluetooth
    case lamp_calls
    case lamp_distance
    case lamp_flights_up
    case lamp_flights_down
    case lamp_currentPace
    case lamp_currentCadence
    case lamp_avgActivePace
    case lamp_gps
    case lamp_gyroscope
    case lamp_magnetometer
    case lamp_screen_state
    case lamp_segment
    case lamp_sms
    case lamp_steps
    case lamp_wifi
    
    var jsonKey: String {
        switch self {
        case .lamp_accelerometer:
            return "lamp.accelerometer"
        case .lamp_accelerometer_motion:
            return "lamp.accelerometer.motion"
        case .lamp_analytics:
            return "lamp.analytics"
        case .lamp_bluetooth:
            return "lamp.bluetooth"
        case .lamp_calls:
            return "lamp.calls"
        case .lamp_distance:
            return "lamp.distance"
        case .lamp_flights_up:
            return "lamp.floors_ascended"
        case .lamp_flights_down:
            return "lamp.floors_descended"
        case .lamp_gps:
            return "lamp.gps"
        case .lamp_gyroscope:
            return "lamp.gyroscope"
        case .lamp_magnetometer:
            return "lamp.magnetometer"
        case .lamp_screen_state:
            return "lamp.screen_state"
        case .lamp_segment:
            return "lamp.segment"
        case .lamp_sms:
            return "lamp.sms"
        case .lamp_steps:
            return "lamp.steps"
        case .lamp_wifi:
            return "lamp.wifi"
        case .lamp_currentPace:
            return "lamp.current_pace"
        case .lamp_currentCadence:
            return "lamp.current_cadence"
        case .lamp_avgActivePace:
            return "lamp.avg_active_pace"
        }
    }
}
