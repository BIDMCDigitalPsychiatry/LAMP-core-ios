// watchkitapp Extension

import Foundation
import WatchKit

struct WatchDeviceInfo {
    static let name = WKInterfaceDevice.current().name
    static let model = WKInterfaceDevice.current().model
    static let osVersion = WKInterfaceDevice.current().systemVersion
    static let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
}
