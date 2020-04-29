// mindLAMP

import Foundation

struct PushUserInfo {
    
    let userInfo: [AnyHashable: Any]
    
    var alert: String? {
        return (userInfo["aps"] as? [String: Any])?["alert"] as? String
    }
    
    private var notificationId: String? {
        return userInfo["notificationId"] as? String
    }
    
    func setDeliveredTime() {
        guard let notificationId = notificationId else {  return }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: notificationId)
    }
    
    var deliverdTime: TimeInterval {
        guard let notificationId = notificationId else { return 0 }
        return UserDefaults.standard.double(forKey: notificationId)
    }
    
    func isExpired() -> Bool {
        guard let notificationId = notificationId else { return false }
        let deliveredTime = UserDefaults.standard.double(forKey: notificationId)
        printDebug("deliveredTime = \(deliveredTime)")
        guard deliveredTime > 0  else {return false}
        guard let expireMilliSec = userInfo["expiry"] as? Double else { return false }
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
            if let urlString = acionObj["page"] {
                return URL(string: urlString)
            }
        }
        return nil
    }

    private func getDefaultPageURL() -> URL? {
        if let page = userInfo["page"] as? String, let pageURL = URL(string: page) {
            return pageURL
        }
        return nil
    }
}
