// watchkitapp Extension

import Foundation
import WatchKit

extension UserAgent {
    static  var defaultAgent: UserAgent {
        return UserAgent(deviceName: WatchDeviceInfo.name, model: WatchDeviceInfo.model, os_version: WatchDeviceInfo.osVersion, app_version: WatchDeviceInfo.appVersion)
    }
}
struct WatchDeviceInfo {
    static let name = WKInterfaceDevice.current().name
    static let model = WKInterfaceDevice.current().model
    static let osVersion = WKInterfaceDevice.current().systemVersion
    static let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
}
