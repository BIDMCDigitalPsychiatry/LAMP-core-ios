//  mindLAMP Consortium

import Foundation

enum PushCommand: String {
    case syncNow = "SynchronizeData"
    case deviceMetric = "DeviceMetrics"
}

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
    
    var command: PushCommand? {
        guard let command = userInfo["command"] as? String else {
            return nil
        }
        return PushCommand(rawValue: command)
    }
    
    func setExpiringTime() {
        guard let notificationId = notificationId else {  return }
        guard let expireMilliSec = expireMilliSeconds else { return }
        let expireSec = expireMilliSec / 1000
        let expiringTime = Date().addingTimeInterval(expireSec)
        UserDefaults.standard.setExpireTimestamp(expiringTime, For: notificationId)
    }
    
    var expiringTime: TimeInterval {
        guard let notificationId = notificationId else { return 0 }
        return UserDefaults.standard.getExpireTimestampFor(notificationId: notificationId)
    }
    
    func isExpired() -> Bool {
        guard let notificationId = notificationId else { return false }
        UserDefaults.standard.removeTimestampForNotification(nid: notificationId)
        guard expiringTime > 0  else {return false}
        //In older versions , we stored the push delivered time.
        return expiringTime <= Date().timeIntervalSince1970
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
