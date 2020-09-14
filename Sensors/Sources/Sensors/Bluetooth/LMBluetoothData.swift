//
//  File.swift
//  
//
//  Created by Zco Engineer on 27/07/20.
//

import Foundation

public struct LMBluetoothData {
    
    public var address: String?
    public var name: String?
    public var rssi: Int?
    public var timestamp = Date().timeInMilliSeconds
}
