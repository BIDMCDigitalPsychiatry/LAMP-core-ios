//
//  ISensorController.swift
//  mindLAMP Consortium
//

import Foundation

public protocol ISensorController {
    var  id: String {get}
    func start()
    func stop()
    func set(label:String)
    var notificationCenter: NotificationCenter {get}
}

extension ISensorController {
    public var notificationCenter: NotificationCenter {
        return NotificationCenter.default
    }
    
    public var  id: String {
        return UUID.init().uuidString
    }
}
//
//extension ISensorController: Equatable {
//    public static func == (lhs: LampSensorCore, rhs: LampSensorCore) -> Bool {
//        return "\(lhs.self)".elementsEqual("\(rhs.self)")
//    }
//}
