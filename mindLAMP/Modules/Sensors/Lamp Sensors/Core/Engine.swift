//
//  Engine.swift
//  CoreAware
//
//  Created by Yuuki Nishiyama on 2018/03/02.
//

import Foundation

public enum DatabaseType {
    case NONE
    case REALM
    // case SQLite
    // case CSV
}

public protocol EngineProtocal {
    
    func save(_ data:LampSensorCoreObject)
    func save(_ data:LampSensorCoreObject, completion:((Error?)->Void)? )
    func save(_ data:Array<LampSensorCoreObject>)
    func save(_ data:Array<LampSensorCoreObject>, completion:((Error?)->Void)?)
    /*
    func fetch(_ objectType: Object.Type?, _ filter:String?) -> Any?
    func fetch(_ objectType: Object.Type?, _ filter:String?, completion:((Any?, Error?)->Void)?)

    func remove(_ objectType: Object.Type?, _ filter:String?)
    func remove(_ objectType: Object.Type?, _ filter:String?, completion:((Error?)->Void)?)
   
    func removeAll(_ objectType: Object.Type?)
    func removeAll(_ objectType: Object.Type?, completion:((Error?)->Void)?)
    
    func close()
    
    func startSync(_ tableName:String, _ objectType: Object.Type?, _ syncConfig:DbSyncConfig)
    */
    func stopSync()
}

open class Engine: EngineProtocal {

    open var config:EngineConfig = EngineConfig()
    
    private init(){

    }
    
    public init(_ config: EngineConfig){
        self.config = config
    }
    
    open class EngineConfig{
        open var type: DatabaseType = DatabaseType.NONE
        open var encryptionKey:String?
        open var path:String?
        open var host:String?
    }
    
    open class Builder {
        
        var config:EngineConfig
        
        public init() {
            config = EngineConfig()
        }
        
        public func setType(_ type: DatabaseType) -> Builder {
            config.type = type
            return self
        }
        
        public func setEncryptionKey(_ key: String?) -> Builder {
            config.encryptionKey = key
            return self
        }
        
        public func setPath(_ path: String?) -> Builder {
            config.path = path
            return self
        }
        
        public func setHost(_ host: String?) -> Builder {
            config.host = host
            return self
        }
        
        public func build() -> Engine {
            switch config.type {
//            case DatabaseType.REALM:
//                return RealmEngine.init(self.config)
            case DatabaseType.NONE:
                return Engine.init()
            default:
                return Engine.init()
            }
        }
    }
    
    open func getDefaultEngine() -> Engine {
        return Builder().build()
    }
    
    public func save(_ data: LampSensorCoreObject) {
        self.save(data, completion:nil)
    }
    
    public func save(_ data: Array<LampSensorCoreObject>) {
        self.save(data, completion:nil)
    }
    
    open func save (_ data:LampSensorCoreObject,completion:((Error?)->Void)?){
        // print("Please orverwrite -save(objects)")
    }
    
    open func save (_ data:Array<LampSensorCoreObject>,completion:((Error?)->Void)?){
        // print("Please orverwrite -save(objects)")
    }
    
    /*
    public func fetch(_ objectType: Object.Type?, _ filter: String?) -> Any? {
        return nil
    }
    
    public func fetch(_ objectType: Object.Type?, _ filter: String?, completion: ((Any?, Error?) -> Void)?) {
        
    }
    
    public func remove(_ objectType: Object.Type?, _ filter: String?) {
        self.remove(objectType, filter, completion: nil)
    }
    
    public func remove(_ objectType: Object.Type?, _ filter: String?, completion: ((Error?) -> Void)?) {
        
    }
    
    public func removeAll(_ objectType: Object.Type?) {
        self.removeAll(objectType, completion: nil)
    }
    
    public func removeAll(_ objectType: Object.Type?, completion: ((Error?) -> Void)?) {
        
    }
    
    open func startSync(_ tableName:String, _ objectType: Object.Type?, _ syncConfig:DbSyncConfig){
        // print("Please overwrite -startSync(tableName:objectType:syncConfig)")
    }*/
    
    open func stopSync() {
        // print("Please orverwirte -stopSync()")
    }
    
    open func close() {
        // print("Please orverwirte -close()")
    }
    
}


