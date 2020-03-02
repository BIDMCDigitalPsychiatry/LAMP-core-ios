//
//  UserDefaults+Extension.swift
//  lampv2
//
//  Created by ZCo Engg Dept on 21/01/20.
//

import Foundation

extension UserDefaults {
    
    enum Key: String {
        case userID = "userID"
        case serverAddress = "serverAddress"
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
    
    func clearAll() {
        UserDefaults.standard.userID = nil
        UserDefaults.standard.serverAddress = nil
    }
}
