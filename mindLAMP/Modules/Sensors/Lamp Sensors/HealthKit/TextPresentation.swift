// mindLAMP

import Foundation
import HealthKit

protocol TextPresentation {
    var stringValue: String? {get}
}

extension HKCategoryValueSleepAnalysis: TextPresentation {
    
    var stringValue: String? {
        switch self {
        case .inBed:
            return "In Bed"
        case .asleep:
            return "In Sleep"
        case .awake:
            return "In Awake"
        @unknown default:
            return nil
        }
    }
}

@available(iOS 13.0, *)
extension HKCategoryValueAudioExposureEvent: TextPresentation {
    var stringValue: String? {
        switch self {
        case .loudEnvironment:
            return "Loud Environment"
        @unknown default:
            return nil
        }
    }
}

extension HKCategoryValueMenstrualFlow: TextPresentation {
    var stringValue: String? {
        switch self {
        case .unspecified:
            return "Unspecified"
        case .light:
            return "Light"
        case .medium:
            return "Medium"
        case .heavy:
            return "Heavy"
        case .none:
            return "None"
        @unknown default:
            return nil
        }
    }
}

extension HKCategoryValueOvulationTestResult: TextPresentation {
    var stringValue: String? {
        switch self {
            
        case .negative:
            return "Negative"
        case .luteinizingHormoneSurge:
            return "Luteinizing Hormone Surge"
        case .indeterminate:
            return "Indeterminate"
        case .estrogenSurge:
            return "Estrogen Surge"
        @unknown default:
            return nil
        }
    }
}

extension HKCategoryValueCervicalMucusQuality: TextPresentation {
    var stringValue: String? {
        switch self {
        case .dry:
            return "Dry"
        case .sticky:
            return "Sticky"
        case .creamy:
            return "Creamy"
        case .watery:
            return "Watery"
        case .eggWhite:
            return "Egg White"
        @unknown default:
            return nil
        }
    }
}

extension HKCategoryValueAppleStandHour: TextPresentation {
    var stringValue: String? {
        switch self {
        case .stood:
            return "Stood"
        case .idle:
            return "Idle"
        @unknown default:
            return nil
        }
    }
}

extension HKBiologicalSex: TextPresentation {
    var stringValue: String? {
        switch self {
            
        case .notSet:
            return "Not Set"
        case .female:
            return "female"
        case .male:
            return "male"
        case .other:
            return "other"
        @unknown default:
            return nil
        }
    }
}

extension HKBloodType: TextPresentation {
    var stringValue: String? {
        switch self {
            
            
        case .notSet:
            return "Not Set"
        case .aPositive:
            return "A Positive"
        case .aNegative:
            return "A Negative"
        case .bPositive:
            return "B Positive"
        case .bNegative:
            return "B Negative"
        case .abPositive:
            return "AB Positive"
        case .abNegative:
            return "AB Negative"
        case .oPositive:
            return "O Positive"
        case .oNegative:
            return "O Negative"
        @unknown default:
            return nil
        }
    }
}

extension HKWheelchairUse: TextPresentation {
    
    var stringValue: String? {
        switch self {
            
        case .notSet:
            return "Not Set"
        case .no:
            return "No"
        case .yes:
            return "Yes"
        @unknown default:
            return nil
        }
    }
}

extension HKFitzpatrickSkinType: TextPresentation {
    
    var stringValue: String? {
        switch self {
        case .notSet:
            return "Not Set"
        case .I:
            return "Pale white skin that always burns easily in the sun and never tans."
        case .II:
            return "White skin that burns easily and tans minimally."
        case .III:
            return "White to light brown skin that burns moderately and tans uniformly."
        case .IV:
            return "Beige-olive, lightly tanned skin that burns minimally and tans moderately."
        case .V:
            return "Brown skin that rarely burns and tans profusely."
        case .VI:
            return "Dark brown to black skin that never burns and tans profusely."
        @unknown default:
            return nil
        }
    }
}
