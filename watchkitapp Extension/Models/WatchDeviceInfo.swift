// watchkitapp Extension

import Foundation
import WatchKit
import LAMP

extension UserAgent {
    static  var defaultAgent: UserAgent {
        return UserAgent(type: WatchDeviceInfo.model, os_version: WatchDeviceInfo.osVersion, app_version: WatchDeviceInfo.appVersion, model: WKInterfaceDevice.current().modelName)
    }
}
struct WatchDeviceInfo {
    static let model = WKInterfaceDevice.current().model
    static let osVersion = WKInterfaceDevice.current().systemVersion
    static let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
}

public extension WKInterfaceDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in
                String.init(validatingUTF8: ptr)
            }
        }
        if let modelcodeide = modelCode, let modelStr = String(stringValue: modelcodeide) {
            return modelStr
        } else {
            return "nil"
        }
    }
}
