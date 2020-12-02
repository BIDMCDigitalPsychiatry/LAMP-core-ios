// mindLAMP

import Foundation
import CoreMotion
import Sensors

//Constructors for sensors
extension SensorDataModel {
    
    init(screenData: ScreenStateData) {
        self.value = Double(screenData.screenState.rawValue)
        self.valueString = screenData.screenState.stringValue
    }
    
    init(callsData: CallsData) {
        self.call_type = callsData.type
        self.call_duration = Double(callsData.duration)
        self.call_trace = callsData.trace
    }
    
    init(locationData: LocationsData) {
        self.latitude = locationData.latitude
        self.longitude = locationData.longitude
        self.altitude = locationData.longitude
    }
    
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
    
    init(activityData: CMMotionActivity) {
       
        self.activity = Activity(activity: activityData)
    }
    
    init(motionData: MotionData) {
        
        //User Acceleration
        let motion = Motion(x: motionData.acceleration.x, y: motionData.acceleration.y, z: motionData.acceleration.z)
        self.motion = motion
        
        //Gravity
        let gravity = Gravitational(x: motionData.gravity.x, y: motionData.gravity.y, z: motionData.gravity.z)
        self.gravity = gravity
        
        //Gyro
        let rotation = Rotational(x: motionData.rotationRate.x, y: motionData.rotationRate.y, z: motionData.rotationRate.z)
        self.rotation = rotation

        //MageticField
//        let magnetic = Magnetic(x: motionData.magneticField.x, y: motionData.magneticField.y, z: motionData.magneticField.z)
//        self.magnetic = magnetic
        
        //Attitude
        let attitude = Attitude(roll: motionData.deviceAttitude.roll, pitch: motionData.deviceAttitude.pitch, yaw: motionData.deviceAttitude.yaw)
        self.attitude = attitude
    }
}

extension Activity {
    init(activity: CMMotionActivity) {
        self.cycling = activity.cycling
        self.running = activity.running
        self.walking = activity.walking
        self.stationary = activity.stationary
        self.in_car = activity.automotive
        self.unknown = activity.unknown
        switch activity.confidence {
        case .low:
            self.confidence = 0.0
        case .medium:
            self.confidence = 0.5
        case.high:
            self.confidence = 1.0
        @unknown default:
            self.confidence = 0.0
        }
        ////start_date: UInt64(activityData.startDate.timeInMilliSeconds)
    }
    
}
