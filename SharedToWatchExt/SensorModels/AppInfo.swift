// mindLAMP

import Foundation

public struct AppInfo {
    public static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
}

public enum DeviceType: String {
    case phone = "iOS"
    case watch = "Apple watchOS"

    public static var displayName: String {
        #if os(iOS)
        return DeviceType.phone.rawValue
        #else
        return DeviceType.watch.rawValue
        #endif
    }
}
