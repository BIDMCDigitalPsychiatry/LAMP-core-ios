// mindLAMP

import Foundation
import UIKit
import LAMP

extension UserAgent {
    
    static var defaultAgent: UserAgent {
        return UserAgent(type: UIDevice.current.model, os_version: UIDevice.current.systemVersion, app_version: AppInfo.version, model: UIDevice.current.modelName)
    }
}

public extension UIDevice {
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
