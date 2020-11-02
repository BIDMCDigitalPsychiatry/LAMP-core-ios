//
//  UserDefaults+Extension.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engg Dept on 21/01/20.
//

import Foundation

extension UserDefaults {
    
    enum Key: String {
        case userID = "userID"
        case serverAddress = "serverAddress"
        case deviceToken = "deviceToken"
        case watchdeviceToken = "watchdeviceToken"
        case sensorRecorderTimestamp = "sensorRecorderTimestamp"
        
        //for iOS only
        case launchURL = "launchURL"
        case nodeJSPath = "nodeJSPath"
        case nodeRootFolder = "nodeRootFolder"
        case version = "version"
        
    }
    
    func setInitalSensorRecorderTimestamp() {
        if sensorRecorderTimestamp == nil {
            sensorRecorderTimestamp = Date().timeIntervalSince1970
        }
    }
    
    var sensorRecorderTimestamp: TimeInterval? {
        get {
            return self.double(forKey: UserDefaults.Key.sensorRecorderTimestamp.rawValue)
        }
        set {
            self.set(newValue, forKey: UserDefaults.Key.sensorRecorderTimestamp.rawValue)
        }
    }
    
    var userID: String? {
        get {
            return self.string(forKey: UserDefaults.Key.userID.rawValue)
        }
        set {
            self.set(newValue, forKey: UserDefaults.Key.userID.rawValue)
        }
    }
    
    var serverAddress: String? {
        get {
            return self.string(forKey: UserDefaults.Key.serverAddress.rawValue)
        }
        set {
            self.set(newValue, forKey: UserDefaults.Key.serverAddress.rawValue)
        }
    }
    
    var deviceToken: String? {
        get {
            return self.string(forKey: UserDefaults.Key.deviceToken.rawValue)
        }
        set {
            self.set(newValue, forKey: UserDefaults.Key.deviceToken.rawValue)
        }
    }
    
//    var watchdeviceToken: String? {
//        get {
//            return self.string(forKey: UserDefaults.Key.watchdeviceToken.rawValue)
//        }
//        set {
//            self.set(newValue, forKey: UserDefaults.Key.watchdeviceToken.rawValue)
//        }
//    }
    
    func clearAll() {
        UserDefaults.standard.userID = nil
        UserDefaults.standard.serverAddress = nil
        UserDefaults.standard.sensorRecorderTimestamp = nil
        UserDefaults.standard.synchronize()
    }
    
//    var logData: String {
//        get {
//            return self.string(forKey: "logData") ?? ""
//        }
//        set {
//            let oldValue = self.string(forKey: "logData") ?? ""
//            let newLog = oldValue + "\n" + newValue
//            self.set(newLog, forKey: "logData")
//        }
//    }
    var launchURL: String? {
        get {
            return self.string(forKey: UserDefaults.Key.launchURL.rawValue)
        }
        set {
            self.set(newValue, forKey: UserDefaults.Key.launchURL.rawValue)
        }
    }
    var nodeJSPath: String? {
        get {
            return self.string(forKey: UserDefaults.Key.nodeJSPath.rawValue)
        }
        set {
            self.set(newValue, forKey: UserDefaults.Key.nodeJSPath.rawValue)
        }
    }
    var nodeRootFolder: String? {
        get {
            return self.string(forKey: UserDefaults.Key.nodeRootFolder.rawValue)
        }
        set {
            self.set(newValue, forKey: UserDefaults.Key.nodeRootFolder.rawValue)
        }
    }
    var version: String? {
        get {
            return self.string(forKey: UserDefaults.Key.version.rawValue)
        }
        set {
            self.set(newValue, forKey: UserDefaults.Key.version.rawValue)
        }
    }
}
