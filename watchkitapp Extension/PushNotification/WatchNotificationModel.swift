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

