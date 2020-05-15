// mindLAMP

import Foundation
import UserNotifications

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

struct DeviceInfoWithToken: Encodable {
    
    var action = "login"
    var device_type = "iOS" //"Android" or "Web"
    var user_agent: String?
    var device_token: String
    
    init(deviceToken: String) {
        device_token = deviceToken
        user_agent = "\(CurrentDevice.model), \(CurrentDevice.osVersion), \(CurrentDevice.appVersion)"
    }
}

struct PayLoadInfo {
    var action = "notification"
    var user_action: String?
    var payload: [String: Any]?
    init(action: RemoteNotification.Action, userInfo: [AnyHashable: Any]) {
        user_action = action.encodableValue
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted)
            //let jsonString = String(bytes: jsonData, encoding: String.Encoding.utf8) ?? ""
            let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
            // you can now cast it with the right type
            if let dictFromJSON = decoded as? [String: Any] {
                payload = dictFromJSON
            }
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func toJSON() -> [String: Any] {
        return ["action": action,
                "user_action" : user_action ?? NSNull(),
                "payload": payload ?? NSNull()
        ]
    }
}

enum PushNotification {

    struct UpdateTokenRequest: Encodable {
        var timestamp: Double
        var sensor = SensorType.lamp_analytics.jsonKey
        var data: DeviceInfoWithToken
        
        init(deviceInfoWithToken: DeviceInfoWithToken) {
            data = deviceInfoWithToken
            timestamp = Date().timeIntervalSince1970 * 1000
        }
    }
    
    struct UpdateTokenResponse: Decodable {
    }
    
    struct UpdateReadRequest {
        var timestamp: Double
        var sensor = SensorType.lamp_analytics
        var data: PayLoadInfo
        
        init(timeInterval: TimeInterval, payLoadInfo: PayLoadInfo) {
            data = payLoadInfo
            timestamp = timeInterval * 1000
        }
        func toJSON() -> [String: Any] {
            return ["timestamp": timestamp,
                    "sensor" : sensor.jsonKey,
                    "data": data.toJSON()
            ]
        }
    }
    
    struct UpdateReadResponse: Decodable {
    }
}
