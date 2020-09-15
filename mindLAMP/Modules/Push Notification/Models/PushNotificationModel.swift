//  mindLAMP Consortium

import Foundation
import UserNotifications
//import Sensors

struct RemoteNotification {

    //UNNotificationExtensionCategory declared in info.plist
    struct Category {
        static let showPageWithActionButton = "OPENPAGE_ACTION"
        static let showPage = "OPENPAGE"
        static let showActionButton = "ACTION"
    }

    enum Action: String {
        case openApp = "OPENPAGE_ACTION_OPEN_APP"
        case openAppNoWebView = "ACTION_OPEN_APP"
        case dismiss //UNNotificationDismissActionIdentifier
        case defaultTap //UNNotificationDefaultActionIdentifier:
        
        var encodableValue: String? {
            switch self {

            case .openApp, .openAppNoWebView:
                return title
            case .dismiss:
                return nil
            case .defaultTap:
                return nil
            }
        }
       
        static func buildFromIdentifier(_ identifier: String) -> RemoteNotification.Action? {
            
            if let customAction = Action(rawValue: identifier) {
                return customAction
            }
            switch identifier {
            case UNNotificationDismissActionIdentifier:
                return .dismiss
            case UNNotificationDefaultActionIdentifier:
                return .defaultTap
            default:
                return nil
            }
        }
        
        var identifier: String {
            switch self {

            case .openApp, .openAppNoWebView:
                return self.rawValue
            case .dismiss:
                return UNNotificationDismissActionIdentifier
            case .defaultTap:
                return UNNotificationDefaultActionIdentifier
            }
        }

        var title: String {
            switch self {
            case .openApp:
                return "Open App"
            case .openAppNoWebView:
                return "Open App"
            case .dismiss, .defaultTap:
                break
            }
            return ""
        }
    }

}
