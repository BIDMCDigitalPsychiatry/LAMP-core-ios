//
//  SensorManager.swift
//  com.awareframework.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2018/11/23.
//

import UIKit

public class SensorManager: NSObject {
    
    /**
     * Singleton
     */
    public static let shared = SensorManager()
    private override init() {
        
    }
    
    public var sensors:Array<LampSensorCore> = []
    
    ////////////////////////////////////////
    
    public func addSensors(_ sensors:[LampSensorCore]){
        for sensor in sensors {
            self.addSensor(sensor)
        }
    }
    
    public func addSensor(_ sensor:LampSensorCore) {
        sensors.append(sensor)
    }
    
    
    public func removeSensors(with type: AnyClass ){
        for sensor in sensors {
            if let index = sensors.firstIndex(of: sensor) {
                if sensor.classForCoder == type {
                    sensors.remove(at: index)
                }
            }
        }
    }
    
    public func removeSensor(id:String){
        for sensor in sensors {
            if let index = sensors.firstIndex(of: sensor) {
                if sensor.id == id {
                    sensors.remove(at: index)
                }
            }
        }
    }
    
    public func getSensor(with sensor:LampSensorCore) -> LampSensorCore? {
        for s in sensors {
            if s == sensor {
                return s
            }
        }
        return nil
    }
    
    public func getSensors(with type: AnyClass ) -> [LampSensorCore]?{
        var foundSensors:Array<LampSensorCore> = []
        for sensor in sensors {
            if type == sensor.classForCoder {
                foundSensors.append(sensor)
            }
        }
        if foundSensors.count == 0 {
            return nil
        }else{
            return foundSensors
        }
    }
    
    public func isExist(with id:String) -> Bool {
        for sensor in sensors {
            if sensor.id == id {
                return true
            }
        }
        return false
    }
    
    public func isExist(with type:AnyClass) -> Bool {
        for sensor in sensors {
            if type == sensor.classForCoder {
                return true
            }
        }
        return false
    }
    
    
    /////////////////////////////////////////////
    public func getSensor(with id: String) -> LampSensorCore? {
        for sensor in sensors{
            if sensor.id == id {
                return sensor;
            }
        }
        return nil
    }
    
    public func syncAllSensors(force:Bool = false){
        for sensor in sensors {
            sensor.sync(force: force)
        }
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
    
    public func enableAllSensors(){
        for sensor in sensors {
            sensor.enable()
        }
    }
    
    public func disableAllSensors(){
        for sensor in sensors {
            sensor.disable()
        }
    }
    
    public func set(label:String){
        for sensor in sensors {
            sensor.set(label: label)
        }
    }
}
