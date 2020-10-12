// mindLAMP

import Foundation
import CoreMotion

//Constructors for sensors
extension SensorDataModel {
    
//    init(screenData: ScreenStateData) {
//        self.value = Double(screenData.screenState.rawValue)
//        self.valueString = screenData.screenState.stringValue
//    }
//    
//    init(callsData: CallsData) {
//        self.call_type = callsData.type
//        self.call_duration = Double(callsData.duration)
//        self.call_trace = callsData.trace
//    }
//    
//    init(locationData: LocationsData) {
//        self.latitude = locationData.latitude
//        self.longitude = locationData.longitude
//        self.altitude = locationData.longitude
//    }
    
    init(rotationRate: CMRotationRate) {
        self.x = rotationRate.x
        self.y = rotationRate.y
        self.z = rotationRate.z
    }
    
    init(accelerationRate: CMAcceleration) {
        self.x = accelerationRate.x
        self.y = accelerationRate.y
        self.z = accelerationRate.z
    }
    
    init(magneticField: CMMagneticField) {
        self.x = magneticField.x
        self.y = magneticField.y
        self.z = magneticField.z
    }
}
