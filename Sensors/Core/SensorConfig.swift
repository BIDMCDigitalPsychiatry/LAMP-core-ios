//
//  SensorConfig.swift
//  mindLAMP Consortium
//

import Foundation

open class SensorConfig{
    
    public var enabled:Bool    = false
    public var debug:Bool      = false
    public var label:String    = ""
    public var deviceId:String = ""
    
    public init(){
        
    }
    
    public convenience init(_ config:Dictionary<String,Any>){
        self.init()
        self.set(config: config)
    }
    
    open func set(config:Dictionary<String,Any>){
        if let enabled = config["enabled"] as? Bool{
            self.enabled = enabled
        }
        
        if let debug = config["debug"] as? Bool {
            self.debug = debug
        }
        
        if let label = config["label"] as? String {
            self.label = label
        }

        if let deviceId = config["deviceId"] as? String {
            self.deviceId = deviceId
        }
    }
}

