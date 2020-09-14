//
//  File.swift
//  
//
//  Created by Zco Engineer on 27/07/20.
//

import Foundation

extension Date {
    
    public var timeInMilliSeconds: Double {
        return self.timeIntervalSince1970 * 1000
    }
}
