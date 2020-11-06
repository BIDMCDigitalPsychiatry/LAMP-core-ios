//  mindLAMP Consortium

import Foundation
import UserNotifications
import UIKit

class NotificationHelper: NSObject {
    
    static let shared = NotificationHelper()
    
    private override init() {}
    
    func registerForPushNotifications(delegate: UNUserNotificationCenterDelegate?) {
        
        UNUserNotificationCenter.current().delegate = delegate
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {(granted, _ ) in
            guard granted else { return }
            self.register()
            self.registerActions()
        }
    }

    func handleLaunchWithRemoteNotification(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard let userInfo = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [String: Any] else { return }
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        let delay = 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            appdelegate.respondedToNotification(remoteAction: RemoteNotification.Action.defaultTap, userInfo: userInfo)
        }
    }
}

private extension NotificationHelper {
    
    func register() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async(execute: {
                UIApplication.shared.registerForRemoteNotifications()
            })
        }
    }
    
    func registerActions() {
        //show web view and  "Open App" action button
        let action1 = UNNotificationAction(identifier: RemoteNotification.Action.openApp.rawValue, title: RemoteNotification.Action.openApp.title,  options: UNNotificationActionOptions.foreground)
        // Define the notification type
        let openPageAndActionCategory =
            UNNotificationCategory(identifier: RemoteNotification.Category.showPageWithActionButton,
                                   actions: [action1],
                                   intentIdentifiers: [],
                                   hiddenPreviewsBodyPlaceholder: "",
                                   options: .customDismissAction)
        
        //show standard notification and "Open App" action button
        /* All of your action objects must have unique identifiers. When handling actions, the identifier is the only way to distinguish one action from another, even when those actions belong to different categories.*/
        let action2 = UNNotificationAction(identifier: RemoteNotification.Action.openAppNoWebView.rawValue, title: RemoteNotification.Action.openAppNoWebView.title,  options: UNNotificationActionOptions.foreground)
        let openAppActionCategory =
            UNNotificationCategory(identifier: RemoteNotification.Category.showActionButton,
                                   actions: [action2],
                                   intentIdentifiers: [],
                                   hiddenPreviewsBodyPlaceholder: "",
                                   options: .customDismissAction)
        // Register the notification type.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([openPageAndActionCategory, openAppActionCategory])
        
    }
}

// MARK: - Push Notifications Delegates

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let deviceTokenStr = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        printDebug("APNS deviceToken = \(deviceTokenStr)")
        
        // Sync to Server and store to userdefault if any change in devicetoken value
        if deviceTokenStr != UserDefaults.standard.deviceToken {
            if User.shared.isLogin() {
                //send to server
                
                let tokenInfo = DeviceInfoWithToken(deviceToken: deviceTokenStr, userAgent: UserAgent.defaultAgent)
                let tokenRerquest = PushNotification.UpdateTokenRequest(deviceInfoWithToken: tokenInfo)
                let lampAPI = NotificationAPI(NetworkConfig.networkingAPI())
                
                lampAPI.sendDeviceToken(request: tokenRerquest) { (isSuccess) in
                    if isSuccess {
                        UserDefaults.standard.deviceToken = deviceTokenStr
                    }
                }
            } else {
                UserDefaults.standard.deviceToken = deviceTokenStr
            }
        }
        
        //show device token for testing purpose
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
//            let appdelegate = UIApplication.shared.delegate as! AppDelegate
//            let alert = UIAlertController(title: "mindLAMP 2 - Token", message: deviceTokenStr, preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "Copy", style: .destructive, handler: { action in
//                  let pasteboard = UIPasteboard.general
//                  pasteboard.string = deviceTokenStr
//            }))
//            appdelegate.window?.rootViewController?.present(alert, animated: true, completion: nil)
//        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        printError("APNS Failed \(error.localizedDescription)")
    }
    
    //The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented.
    //The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Swift.Void) {
        
        //let userInfo = notification.request.content.userInfo
        completionHandler([.alert, .badge, .sound])
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let pushInfo = PushUserInfo(userInfo: userInfo)
        printToFile("userInfo = \(userInfo)")
        print("userInfo = \(userInfo)")
        pushInfo.setDeliveredTime()
        completionHandler(UIBackgroundFetchResult.noData)
        
    }
    
    // The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction.
    //The delegate must be set before the application returns from applicationDidFinishLaunching:.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Swift.Void) {
        
        guard let remoteAction = RemoteNotification.Action.buildFromIdentifier(response.actionIdentifier) else { return }
        respondedToNotification(remoteAction: remoteAction, userInfo: response.notification.request.content.userInfo)
        printToFile("response.notification.request.content.userInfo = \(response.notification.request.content.userInfo)")
        print("response.notification.request.content.userInfo = \(response.notification.request.content.userInfo)")
        completionHandler()
    }
    
    func respondedToNotification(remoteAction: RemoteNotification.Action, userInfo: [AnyHashable: Any]) {
        
        var action = remoteAction
        let pushInfo = PushUserInfo(userInfo: userInfo)
        if pushInfo.isExpired() {
            action = .dismiss
            
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            let alert = UIAlertController(title: "alert.lamp.title".localized, message: "alert.notification.expired".localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "alert.button.ok".localized, style: .destructive, handler: { action in
               }))
            appdelegate.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }

        switch action {
        case .openAppNoWebView, .openApp, .defaultTap:
            guard let pageURL = pushInfo.pageURLForAction(action) else { break }
            _ = openWebPage(pageURL, title: pushInfo.alert)
        case .dismiss:
            ()
        }
        
        //update server
        let payLoadInfo = PayLoadInfo(userAction: action.encodableValue, userInfo: userInfo, userAgent: UserAgent.defaultAgent)
        let acknoledgeRequest = PushNotification.UpdateReadRequest(timeInterval: pushInfo.deliverdTime, payLoadInfo: payLoadInfo)
        let lampAPI = NotificationAPI(NetworkConfig.networkingAPI())
        lampAPI.sendPushAcknowledgement(request: acknoledgeRequest)
    }
    
    private func openWebPage(_ pageURL: URL, title: String?) -> Bool {
        
        let webViewController: WebViewController = WebViewController.getController()
        if let navController = self.window?.rootViewController as? UINavigationController {
            if let existiWebController = navController.topViewController as? WebViewController, existiWebController.pageURL.absoluteString ==  pageURL.absoluteString {
            } else {
                webViewController.title = title
                webViewController.pageURL = pageURL
                navController.pushViewController(webViewController, animated: true)
                return true
            }
        }
        return false
    }

}
