//
//  HKWorkoutActivityType+Extension.swift
//  mindLAMP Consortium
//
//  Created by Zco Engineer on 17/03/20.
//

import Foundation
import HealthKit

extension HKWorkoutActivityType {
    
    var stringType: String {
        switch self {
        case .running:
            return "running"
        case .golf:
            return "golf"
        case .hiking:
            return "hiking"
        case .dance:
            return "dance"
        case .yoga:
            return "yoga"
        case .soccer:
            return "soccer"
        case .rowing:
            return "rowing"
        case .tennis:
            return "tennis"
        case .stairs:
            return "stairs"
        case .bowling:
            return "bowling"
        case .cycling:
            return "cycling"
        case .fishing:
            return "fishing"
        case .walking:
            return "walking"
        case .pilates:
            return "pilates"
        case .baseball:
            return "baseball"
        case .badminton:
            return "badminton"
        case .gymnastics:
            return "gymnastics"
        case .swimming:
            return "swimming"
        case .basketball:
            return "basketball"
        case .snowSports:
            return "snow_sports"
        case .handCycling:
            return "hand_cycling"
        case .tableTennis:
            return "table_tennis"
        case .coreTraining:
            return "core_training"
        case .snowboarding:
            return "snowboarding"
        case .stepTraining:
            return "step_training"
        case .other:
            return "other"
        default:
            return "---"
        }
    }
}

