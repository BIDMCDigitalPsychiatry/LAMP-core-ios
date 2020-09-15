//
//  SensorManager.swift
//  mindLAMP Consortium
//

//import UIKit

public class SensorManager {
    
    /**
     * Singleton
     */
    public static let shared = SensorManager()
    
    public init() {
        
    }
    
    public var sensors: Array<ISensorController> = []
    
    ////////////////////////////////////////
    
    public func addSensors(_ sensors: [ISensorController]){
        for sensor in sensors {
            self.addSensor(sensor)
        }
    }
    
    public func addSensor(_ sensor: ISensorController) {
        sensors.append(sensor)
    }
    
    
//    public func removeSensors(with type: AnyClass){
//        for sensor in sensors {
//            if let index = sensors.firstIndex(of: sensor) {
//                if type(of: sensor) == type(of: type) {
//                    sensors.remove(at: index)
//                }
//            }
//        }
//    }
    
//    public func removeSensor(id:String){
//        for sensor in sensors {
//            if let index = sensors.firstIndex(of: sensor) {
//                if sensor.id == id {
//                    sensors.remove(at: index)
//                }
//            }
//        }
//    }
//    
//    public func getSensor(with sensor: ISensorController) -> ISensorController? {
//        for s in sensors {
//            if s == sensor {
//                return s
//            }
//        }
//        return nil
//    }
    
//    public func getSensors(with type: AnyClass ) -> [LampSensorCore]?{
//        var foundSensors:Array<LampSensorCore> = []
//        for sensor in sensors {
//            if sensor is type(of: type) {
//                foundSensors.append(sensor)
//            }
//        }
//        if foundSensors.count == 0 {
//            return nil
//        }else{
//            return foundSensors
//        }
//    }
    
    public func isExist(with id:String) -> Bool {
        for sensor in sensors {
            if sensor.id == id {
                return true
            }
        }
        return false
    }
//
//    public func isExist(with type:AnyClass) -> Bool {
//        for sensor in sensors {
//            if type == sensor.classForCoder {
//                return true
//            }
//        }
//        return false
//    }
    
    
    /////////////////////////////////////////////
    public func getSensor(with id: String) -> ISensorController? {
        for sensor in sensors{
            if sensor.id == id {
                return sensor;
            }
        }
        return nil
    }
    
    public func startAllSensors(){
        for sensor in sensors {
            sensor.start()
        }
    }
    
    public func stopAllSensors(){
        for sensor in sensors {
            sensor.stop()
        }
    }
    
    public func set(label:String){
        for sensor in sensors {
            sensor.set(label: label)
        }
    }
}
