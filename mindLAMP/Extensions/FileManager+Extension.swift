//
//  FileManager+Extension.swift
//  lampv2
//
//  Created by ZCo Engg Dept on 03/01/20.
//

import Foundation

extension FileManager {
    static let nodeFolder = "nodejs-project"
    static var documentFolder: String {
        get {
            return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        }
    }
    
    static var homeURL: URL {
        get {
            return URL(fileURLWithPath: documentFolder).appendingPathComponent(nodeFolder)
        }
    }
    
    func isFolder(contentName: String) -> Bool {
        
        var isDir: ObjCBool = false
        
        if fileExists(atPath: contentName, isDirectory:&isDir) {
            if isDir.boolValue {
                return true
            }
        }
        return false
    }
}
