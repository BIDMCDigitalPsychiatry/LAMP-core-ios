// watchkitapp Extension
//https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/pushing_background_updates_to_your_app
//https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns#2947607

import Foundation

struct Utils {
    static func postNotificationOnMainQueueAsync(name: NSNotification.Name) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: nil)
        }
    }
}

enum WatchNotification {
    
    struct UpdateTokenRequest: Encodable {
        var timestamp: Double
        var sensor = WatchSensorType.lamp_analytics.jsonKey
        var data: WatchInfoWithToken
        
        init(deviceInfoWithToken: WatchInfoWithToken) {
            data = deviceInfoWithToken
            timestamp = Date().timeIntervalSince1970 * 1000
        }
    }
    
    struct UpdateTokenResponse: Decodable {
    }
    
}

struct WatchInfoWithToken: Encodable {
    
    var action = "login"
    var device_type = "WatchOS" //"iOS", "Android" or "Web"
    var user_agent: String?
    var device_token: String
    
    init(deviceToken: String) {
        device_token = deviceToken
        user_agent = "\(WatchDeviceInfo.model), \(WatchDeviceInfo.osVersion), \(WatchDeviceInfo.appVersion)"
    }
}

