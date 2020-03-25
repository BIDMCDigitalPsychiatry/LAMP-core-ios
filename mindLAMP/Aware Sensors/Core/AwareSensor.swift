//
//  AwareSensor.swift
//  com.aware.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2018/03/08.
//

import Foundation

public protocol ISensorController {
    var  id:String {get}
    func start()
    func sync(force:Bool)
    func isEnabled() -> Bool
    func enable()
    func disable()
    func stop()
    func set(label:String)
}

open class AwareSensor: NSObject,ISensorController {

    public let notificationCenter = NotificationCenter.default
    public var syncState  = false
    public var dbEngine: Engine? = nil
    public var syncConfig: DbSyncConfig? = nil
    
    public var id: String = UUID.init().uuidString
    
    public override init(){
        // print("*** Please do not use this initializer! ***");
    }
    
    deinit {
        notificationCenter.removeObserver(self,
                                          name: Notification.Name.Aware.dbSyncRequest ,
                                          object: nil)
    }
    
    open func initializeDbEngine(config: SensorConfig) {
        dbEngine?.close()
        
        dbEngine = Engine.Builder()
            .setPath(config.dbPath)
            .setType(config.dbType)
            .setHost(config.dbHost)
            .setEncryptionKey(config.dbEncryptionKey)
            .build()
    }
    
    open func start() {
        // print("*** Please orverwrite -start() method! ***");
    }
    
    open func stop() {
        // print("*** Please orverwrite -stop() method! ***");
    }
    
    @objc open func sync(force:Bool=false){
        // print("*** Please orverwrite -sync() method! ***");
    }
    
    open func enable() {
        if !syncState {
            notificationCenter.addObserver(self,
                                           selector: #selector(sync),
                                           name: Notification.Name.Aware.dbSyncRequest,
                                           object: nil)
            syncState = true
        }
    }
    
    open func disable() {
        if syncState {
            notificationCenter.removeObserver(self,
                                              name: Notification.Name.Aware.dbSyncRequest ,
                                              object: nil)
            syncState = false
        }
    }
    
    open func isEnabled() -> Bool {
        return syncState
    }
    
    open func set(label: String) {
        // print("*** Please orverwrite -set(label) method! ***");
    }
    
}

