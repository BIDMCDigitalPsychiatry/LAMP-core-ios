// mindLAMP

import Foundation
import UIKit

struct UserAgent {
    var model: String
    var os_version: String
    var app_version: String
}

extension UserAgent {
    func toString() -> String {
        return "\(app_version), \(model), \(os_version)"
    }
}

struct DeviceInfoWithToken: Encodable {
    
    var action = SensorType.AnalyticAction.login.rawValue
    var device_type: String// = "iOS" //"Android" or "Web"
    var user_agent: String?
    var device_token: String?
    
    init(deviceToken: String?, userAgent: UserAgent?) {
        self.device_token = deviceToken
        self.user_agent = userAgent?.toString()
        self.device_type = DeviceType.displayName
    }
}

struct PayLoadInfo {
    var action = SensorType.AnalyticAction.notification.rawValue
    var user_action: String?
    var device_type: String// = "iOS" //"Android" or "Web"
    var user_agent: UserAgent?
    var payload: [String: Any]?
    init(userAction: String?, userInfo: [AnyHashable: Any], userAgent: UserAgent?) {
        user_action = action
        self.user_agent = userAgent
        self.device_type = DeviceType.displayName
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
                "content": payload ?? NSNull(),
                "device_type": device_type,
                "user_agent": user_agent?.toString() ?? NSNull()
        ]
    }
}

enum PushNotification {

    struct UpdateTokenRequest: Encodable {
        var timestamp: Double
        var sensor = SensorType.lamp_analytics.lampIdentifier
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
                    "sensor" : sensor.lampIdentifier,
                    "data": data.toJSON()
            ]
        }
    }
    
    struct UpdateReadResponse: Decodable {
    }
}
