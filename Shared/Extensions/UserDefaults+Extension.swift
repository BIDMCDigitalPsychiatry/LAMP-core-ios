//
//  UserDefaults+Extension.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engg Dept on 21/01/20.
//

import Foundation

extension Date {
    var timeInMilliSeconds: Double {
        return self.timeIntervalSince1970 * 1000
    }
}

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
        
        case notificationTimestamps = "notificationTimestamps"
        case activityAPILastAccessedDate = "activityAPILastAccessedDate"
    }
    
    var lpmCount: Int {
        get {
            let count = self.integer(forKey: "lpmCount")
            self.setValue(count + 1, forKey: "lpmCount")
            return count
        }
    }
    
    var activityAPILastAccessedDate: Date {
        get {
            return (self.object(forKey: UserDefaults.Key.activityAPILastAccessedDate.rawValue)) as? Date ?? Date.init(timeIntervalSince1970: 0)
        }
        set {
            self.set(newValue, forKey: UserDefaults.Key.activityAPILastAccessedDate.rawValue)
        }
    }
    
    var notificationTimestamps: [String: Double]? {
        get {
            return self.object(forKey: UserDefaults.Key.notificationTimestamps.rawValue) as? [String: Double]
        }
        set {
            self.set(newValue, forKey: UserDefaults.Key.notificationTimestamps.rawValue)
        }
    }
    
    func removeTimestampForNotification(nid: String) {
        var dictTimestamps = notificationTimestamps
        dictTimestamps?.removeValue(forKey: nid)
        
        notificationTimestamps = dictTimestamps
    }
    
    func removeAllNotificationTimestamps() {
        removeObject(forKey: UserDefaults.Key.notificationTimestamps.rawValue)
    }
    
//    func setTimestampForNotificationId(nId: String) {
//        var dictTimestamps = notificationTimestamps ?? [String: Double]()
//        dictTimestamps[nId] = Date().timeIntervalSince1970
//
//        notificationTimestamps = dictTimestamps
//    }
    
    func setExpireTimestamp(_ timeStamp: Date, For notificationId: String) {
        var dictTimestamps = notificationTimestamps ?? [String: Double]()
        dictTimestamps[notificationId] = timeStamp.timeIntervalSince1970
        
        notificationTimestamps = dictTimestamps
    }
    
    func getExpireTimestampFor(notificationId: String) -> Double {
        let dictTimestamps = notificationTimestamps
        return dictTimestamps?[notificationId] ?? 0
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
    var suiteName: String {
        return LampURL.groupname
    }
    var userIDShared: String? {
        get {
            if let userDefaults = UserDefaults(suiteName: suiteName) {
                if let value = userDefaults.string(forKey: "userid") {
                    return value
                }
            }
            return nil
        }
        set {
            if let userDefaults = UserDefaults(suiteName: suiteName) {
                if newValue == nil {
                    userDefaults.removeObject(forKey: "userid")
                } else {
                    userDefaults.set(newValue as AnyObject, forKey: "userid")
                }
            }
        }
    }
    
    var passwordShared: String? {
        get {
            if let userDefaults = UserDefaults(suiteName: suiteName) {
                if let value = userDefaults.string(forKey: "password") {
                    return value
                }
            }
            return nil
        }
        set {
            if let userDefaults = UserDefaults(suiteName: suiteName) {
                if newValue == nil {
                    userDefaults.removeObject(forKey: "password")
                } else {
                    userDefaults.set(newValue as AnyObject, forKey: "password")
                }
            }
        }
    }
    
    var serverAddressShared: String? {
        get {
            if let userDefaults = UserDefaults(suiteName: suiteName) {
                if let value = userDefaults.string(forKey: "serverAddress") {
                    return value
                }
            }
            return nil
        }
        set {
            if let userDefaults = UserDefaults(suiteName: suiteName) {
                if newValue == nil {
                    userDefaults.removeObject(forKey: "serverAddress")
                } else {
                    userDefaults.set(newValue as AnyObject, forKey: "serverAddress")
                }
            }
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
        setValue(0, forKey: "lpmCount")
        UserDefaults.standard.userIDShared = nil
        UserDefaults.standard.passwordShared = nil
        UserDefaults.standard.serverAddressShared = nil
        UserDefaults.standard.activityAPILastAccessedDate = Date.init(timeIntervalSince1970: 0)
        
        UserDefaults.standard.removeObject(forKey: UserDefaults.Key.userID.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaults.Key.serverAddress.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaults.Key.sensorRecorderTimestamp.rawValue)
        removeAllNotificationTimestamps()
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
