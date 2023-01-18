// WatchNotificationService

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            //bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
            let userInfo = bestAttemptContent.userInfo
            if let activity_name = userInfo["title"] as? String {
                bestAttemptContent.body = String(format: "notification.activity.alert".localized, arguments: ["\(activity_name)"])
            }
            
            contentHandler(bestAttemptContent)
        } else {
            contentHandler(bestAttemptContent ?? request.content)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
