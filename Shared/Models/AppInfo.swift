// mindLAMP

import Foundation

struct AppInfo {
    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
}

enum DeviceType: String {
    case phone = "iOS"
    case watch = "Apple watchOS"
    
    static var displayName: String {
        #if os(iOS)
        return DeviceType.phone.rawValue
        #else
        return DeviceType.watch.rawValue
        #endif
    }
}
