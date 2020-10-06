// mindLAMP

import Foundation
import CoreMotion
import Sensors

//Constructors for sensors
extension SensorDataModel {
    
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
        let magnetic = Magnetic(x: motionData.magneticField.x, y: motionData.magneticField.y, z: motionData.magneticField.z)
        self.magnetic = magnetic
        
        //Attitude
        let attitude = Attitude(roll: motionData.deviceAttitude.roll, pitch: motionData.deviceAttitude.pitch, yaw: motionData.deviceAttitude.yaw)
        self.attitude = attitude
    }
}
