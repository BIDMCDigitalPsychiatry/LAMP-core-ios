// NotificationService
import Foundation
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        // print("received push \(request.identifier)")
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        bestAttemptContent?.userInfo["apns-collapse-id"] = request.identifier
        // update badge
        let badgeCount = UserDefaults.standard.badgeCountShared + 1
        bestAttemptContent?.badge = badgeCount as NSNumber
        UserDefaults.standard.badgeCountShared = badgeCount
        defer {
            contentHandler(bestAttemptContent ?? request.content)
        }
        if let bestAttemptContent = bestAttemptContent {
            let userInfo = bestAttemptContent.userInfo
            
            var isActionExist = false
            var isPageExist = false
            // Modify the notification content here...
            //bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
            
            if let actionArry = userInfo["actions"] as? [[String: String]],
                actionArry.count > 0,
                actionArry[0]["name"]?.lowercased() == "open app" {
                isActionExist = true
            }
            
            if let urlImageString = userInfo["page"] as? String, nil != URL(string: urlImageString) {
                /// Add the category so the "Open Board" action button is added.
                isPageExist = true
            }
            
            if isPageExist && isActionExist {
                bestAttemptContent.categoryIdentifier = "OPENPAGE_ACTION"
            } else if isPageExist {
                bestAttemptContent.categoryIdentifier = "OPENPAGE"
            } else if isActionExist {
                bestAttemptContent.categoryIdentifier = "ACTION"
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
}
