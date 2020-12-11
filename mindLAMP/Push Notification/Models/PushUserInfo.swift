//  mindLAMP Consortium

import Foundation

struct PushUserInfo {
    
    let userInfo: [AnyHashable: Any]
    
    var alert: String? {
        return (userInfo["aps"] as? [String: Any])?["alert"] as? String
    }
    
    var notificationId: String? {
        return userInfo["notificationId"] as? String
    }
    
    var identifier: String? {
        return (userInfo["apns-collapse-id"] as? String) ?? notificationId
    }
    
    var expireMilliSeconds: Double? {
        return userInfo["expiry"] as? Double
    }
    
    func setDeliveredTime() {
        guard let notificationId = notificationId else {  return }
        UserDefaults.standard.setTimestampForNotificationId(nId: notificationId)
    }
    
    var deliverdTime: TimeInterval {
        guard let notificationId = notificationId else { return 0 }
        return UserDefaults.standard.getTimestampForNotificationId(nId: notificationId)
    }
    
    func isExpired() -> Bool {
        guard let notificationId = notificationId else { return false }
        let deliveredTime = UserDefaults.standard.getTimestampForNotificationId(nId: notificationId)
        UserDefaults.standard.removeTimestampForNotification(nid: notificationId)
        printDebug("deliveredTime = \(deliveredTime)")
        guard deliveredTime > 0  else {return false}
        guard let expireMilliSec = expireMilliSeconds else { return false }
        let expireSec = expireMilliSec / 1000
        let lapsedIntervals = Date().timeIntervalSince1970 - deliveredTime
        return lapsedIntervals > expireSec
    }
    
    func pageURLForAction(_ action: RemoteNotification.Action) -> URL? {
        switch action {

        case .openApp:
            return getPageURLForActionButton(action)
        case .openAppNoWebView:
            return getPageURLForActionButton(action)
        case .dismiss:
            return nil
        case .defaultTap:
            return getDefaultPageURL()
        }
    }
    
    private func getPageURLForActionButton(_ action: RemoteNotification.Action) -> URL? {
        if let actionArry = userInfo["actions"] as? [[String: String]],
            let acionObj = actionArry.first(where:{ $0["name"] == action.title}) {
            if let page = acionObj["page"] {
                return URL(string: Endpoint.appendURLTokenTo(urlString: page))
            }
        }
        return getDefaultPageURL()
    }

    private func getDefaultPageURL() -> URL? {
        if let page = userInfo["page"] as? String, let pageURL = URL(string: Endpoint.appendURLTokenTo(urlString: page)) {
            return pageURL
        }
        return nil
    }
}
