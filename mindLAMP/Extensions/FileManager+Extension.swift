//
//  FileManager+Extension.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engg Dept on 03/01/20.
//

import Foundation

extension FileManager {
//    static var nodeFolder: String {
//        return UserDefaults.standard.nodeRootFolder ?? "nodejs-project"
//    }
    static var documentFolder: String {
        get {
            return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        }
    }
    
//    static var nodeJSPath: URL {
//        get {
//            let jsFile = UserDefaults.standard.nodeJSPath ?? "\(nodeFolder)/index.js"
//            return URL(fileURLWithPath: documentFolder).appendingPathComponent(jsFile)
//        }
//    }
    
//    static var homeURL: URL {
//        get {
//            return URL(fileURLWithPath: documentFolder).appendingPathComponent(nodeFolder)
//        }
//    }
    
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
