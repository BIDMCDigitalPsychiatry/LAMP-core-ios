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
                return "lamp.apple_standtime"
            }
            else if self == .environmentalAudioExposure {
                return "lamp.environmental_audioexposure"
            }
            else if self == .headphoneAudioExposure {
                return "lamp.headphone_audioexposure"
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
            return "lamp.lean_bodymass"
        case .waistCircumference:
            return "lamp.waist_wircumference"
        case .distanceWalkingRunning:
            return "lamp.distance_walkingrunning"
        case .distanceCycling:
            return "lamp.distance_cycling"
        case .distanceWheelchair:
            return "lamp.distance_wheelchair"
        case .basalEnergyBurned:
            return "lamp.basal_energyburned"
        case .activeEnergyBurned:
            return "lamp.active_energyBurned"
        case .flightsClimbed:
            return "lamp.flights_climbed"
        case .nikeFuel:
            return "lamp.nike_fuel"
        case .appleExerciseTime:
            return "lamp.apple_exercisetime"
        case .pushCount:
            return "lamp.push_count"
        case .distanceSwimming:
            return "lamp.distance_swimming"
        case .swimmingStrokeCount:
            return "lamp.swimming_strokecount"
        case .vo2Max:
            return "lamp.vo2Max"
        case .distanceDownhillSnowSports:
            return "lamp.distance_downhillsnowsports"
            
        case .bodyTemperature:
            return "lamp.body_temperature"
        case .basalBodyTemperature:
            return "lamp.basal_bodytemperature"
        case .restingHeartRate:
            return "lamp.resting_heartrate"
        case .walkingHeartRateAverage:
            return "lamp.walking_heartrateaverage"
        case .heartRateVariabilitySDNN:
            return "lamp.heartratevariability_sdnn"
        case .oxygenSaturation:
            return "lamp.oxygen_saturation"
        case .peripheralPerfusionIndex:
            return "lamp.peripheral_perfusionindex"
        case .bloodGlucose:
            return "lamp.blood_glucose"
        case .numberOfTimesFallen:
            return "lamp.numberoftimes_fallen"
        case .electrodermalActivity:
            return "lamp.electrodermal_activity"
        case .inhalerUsage:
            return "lamp.inhaler_usage"
        case .insulinDelivery:
            return "lamp.insulin_delivery"
        case .bloodAlcoholContent:
            return "lamp.blood_alcoholcontent"
        case .forcedVitalCapacity:
            return "lamp.forced_vitalcapacity"
        case .forcedExpiratoryVolume1:
            return "lamp.forced_expiratoryvolume1"
        case .peakExpiratoryFlowRate:
            return "lamp.peak_expiratoryflowrate"
            
        case .dietaryFatTotal:
            return "lamp.dietaryfattotal"
        case .dietaryFatPolyunsaturated:
            return "lamp.dietaryfatpolyunsaturated"
        case .dietaryFatMonounsaturated:
            return "lamp.dietaryfatmonounsaturated"
        case .dietaryFatSaturated:
            return "lamp.dietaryfatsaturated"
        case .dietaryCholesterol:
            return "lamp.dietarycholesterol"
        case .dietarySodium:
            return "lamp.dietarysodium"
        case .dietaryCarbohydrates:
            return "lamp.dietarycarbohydrates"
        case .dietaryFiber:
            return "lamp.dietaryfiber"
        case .dietarySugar:
            return "lamp.dietarysugar"
        case .dietaryEnergyConsumed:
            return "lamp.dietaryenergyconsumed"
        case .dietaryProtein:
            return "lamp.dietaryprotein"
        case .dietaryVitaminA:
            return "lamp.dietaryvitamina"
        case .dietaryVitaminB6:
            return "lamp.dietaryvitaminb6"
        case .dietaryVitaminB12:
            return "lamp.dietaryvitaminb12"
        case .dietaryVitaminC:
            return "lamp.dietaryvitaminc"
        case .dietaryVitaminD:
            return "lamp.dietaryvitamind"
        case .dietaryVitaminE:
            return "lamp.dietaryvitamine"
        case .dietaryVitaminK:
            return "lamp.dietaryvitamink"
        case .dietaryCalcium:
            return "lamp.dietarycalcium"
        case .dietaryIron:
            return "lamp.dietaryiron"
        case .dietaryThiamin:
            return "lamp.dietarythiamin"
        case .dietaryRiboflavin:
            return "lamp.dietaryriboflavin"
        case .dietaryNiacin:
            return "lamp.dietaryniacin"
        case .dietaryFolate:
            return "lamp.dietaryfolate"
        case .dietaryBiotin:
            return "lamp.dietarybiotin"
        case .dietaryPantothenicAcid:
            return "lamp.dietarypantothenicacid"
        case .dietaryPhosphorus:
            return "lamp.dietaryphosphorus"
        case .dietaryIodine:
            return "lamp.dietaryiodine"
        case .dietaryMagnesium:
            return "lamp.dietarymagnesium"
        case .dietaryZinc:
            return "lamp.dietaryzinc"
        case .dietarySelenium:
            return "lamp.dietaryselenium"
        case .dietaryCopper:
            return "lamp.dietarycopper"
        case .dietaryManganese:
            return "lamp.dietarymanganese"
        case .dietaryChromium:
            return "lamp.dietarychromium"
        case .dietaryMolybdenum:
            return "lamp.dietarymolybdenum"
        case .dietaryChloride:
            return "lamp.dietarychloride"
        case .dietaryPotassium:
            return "lamp.dietarypotassium"
        case .dietaryCaffeine:
            return "lamp.dietarycaffeine"
        case .dietaryWater:
            return "lamp.dietarywater"
        case .dietaryCopper:
            return "lamp.uvexposure"
            
        default:
            return "lamp.\(self.rawValue)"
        }
    }
}

#if os(iOS)
extension HKCategoryTypeIdentifier: LampDataKeysProtocol {
    
    public var lampIdentifier: String {
        
        switch self {
        case .sleepAnalysis:
            return "lamp.sleep"
        case .appleStandHour:
            return "lamp.apple_standhour"
        case .cervicalMucusQuality:
            return "lamp.cervical_mucusquality"
        case .ovulationTestResult:
            return "lamp.ovulation_testresult"
        case .menstrualFlow:
            return "lamp.menstrualflow"
        case .intermenstrualBleeding:
            return "lamp.intermenstrual_bleeding"
        case .sexualActivity:
            return "lamp.sexual_activity"
        case .mindfulSession:
            return "lamp.mindful_session"
        case .highHeartRateEvent:
            return "lamp.high_heartrateevent"
        case .lowHeartRateEvent:
            return "lamp.lowheartrate_event"
        case .irregularHeartRhythmEvent:
            return "lamp.irregular_heartrhythmevent"
        case .environmentalAudioExposureEvent:
            return "lamp.audio_exposureevent"
        case .toothbrushingEvent:
            return "lamp.toothbrushingevent"
        default:
            return "lamp.\(self.rawValue)"
        }
    }
}
#endif
extension HKCharacteristicTypeIdentifier: LampDataKeysProtocol {
    
    public var lampIdentifier: String {
        switch self {
        case .biologicalSex:
            return "lamp.biologicalsex"
        case .bloodType:
            return "lamp.bloodtype"
        case .dateOfBirth:
            return "lamp.dob"
        case .fitzpatrickSkinType:
            return "lamp.skintype"
        case .wheelchairUse:
            return "lamp.wheelchairuse"
            
        default:
            return "lamp.\(self.rawValue)"
        }
    }
}
