// mindLAMP

import Foundation
import UIKit
import LAMP

extension UserAgent {
    static var defaultAgent: UserAgent {
        return UserAgent(model: UIDevice.current.model, os_version: UIDevice.current.systemVersion, app_version: AppInfo.version)
    }
}
