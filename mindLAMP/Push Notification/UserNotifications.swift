//  mindLAMP Consortium

import Foundation
import UserNotifications
import UIKit
import SwiftUI
import LAMP

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
        let delay = 3.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            appdelegate.respondedToNotification(remoteAction: RemoteNotification.Action.defaultTap, userInfo: userInfo)
        }
    }
    
    func removeNotification(identifier: String) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
        UserDefaults.standard.removeTimestampForNotification(nid: identifier)
        DispatchQueue.main.async {
            (UIApplication.shared.delegate as? AppDelegate)?.calculateBadgeCount()
        }
    }
    
    //we can execute when ever app active
    func removeAllExpiredNotifications() {
        //we should not remove immediatly, suppose a user tap on notification, we have to show "Expired!" message.
        DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
            guard let timeStampDict = UserDefaults.standard.notificationTimestamps else { return }
            for (notId, expiringTime) in timeStampDict {
                if expiringTime <= Date().timeIntervalSince1970 { //is expired
                    UserDefaults.standard.removeTimestampForNotification(nid: notId)
                }
            }
        }
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    @objc func fireNotificationExpire(timer: Timer) {
        guard let userInfo = timer.userInfo as? [AnyHashable : Any] else {
            timer.invalidate()
            return }
        let pushInfo = PushUserInfo(userInfo: userInfo)
        if let identifier = pushInfo.identifier {
            removeNotification(identifier: identifier)
        }
        timer.invalidate()
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
        
//        DispatchQueue.main.async {
//            UIPasteboard.general.string = deviceTokenStr
//        }
        
        // Sync to Server and store to userdefault if any change in devicetoken value
        if deviceTokenStr != UserDefaults.standard.deviceToken {
            if User.shared.isLogin() {
                //send to server
                guard let participantId = User.shared.userId else {
                    return
                }
                
                let tokenInfo = DeviceInfoWithToken(deviceToken: deviceTokenStr, userAgent: UserAgent.defaultAgent, action: nil)
               
                let event = SensorEvent(timestamp: Date().timeInMilliSeconds, sensor: SensorType.lamp_analytics.lampIdentifier, data: tokenInfo)
                
                let endPoint =  String(format: Endpoint.participantSensorEvent.rawValue, participantId)
                let data = RequestData(endpoint: endPoint, requestTye: HTTPMethodType.post, data: event)
                let lampAPI = NetworkConfig.networkingAPI()
                lampAPI.makeWebserviceCall(with: data) { (response: Result<EmptyResponse>) in
                    switch response {
                    case .failure(_):
                        break
                    case .success(_):
                        UserDefaults.standard.deviceToken = deviceTokenStr
                    }
                }
              
                /*
                guard let authheader = Endpoint.getSessionKey(), let participantId = User.shared.userId else {
                    return
                }
                OpenAPIClientAPI.basePath = LampURL.baseURLString
                OpenAPIClientAPI.customHeaders = ["Authorization": "Basic \(authheader)", "Content-Type": "application/json"]
                
                let publisher = SensorEventAPI.sensorEventCreate(participantId: participantId, sensorEvent: event, apiResponseQueue: DispatchQueue.global())
                subscriber = publisher.sink { value in
                    switch value {
                    case .failure(let error):
                        printError("loginSensorEventCreate error \(error.localizedDescription)")
                    case .finished:
                        UserDefaults.standard.deviceToken = deviceTokenStr
                    }
                } receiveValue: { (stringValue) in
                    print("APNS register = \(stringValue)")
                }*/
            } else {
                UserDefaults.standard.deviceToken = deviceTokenStr
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        printError("APNS Failed \(error.localizedDescription)")
    }
    
    //The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented.
    //The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Swift.Void) {
        completionHandler([.banner, .badge, .sound])
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let pushInfo = PushUserInfo(userInfo: userInfo)

        pushInfo.setExpiringTime()
        
        if let livingTime = pushInfo.expireMilliSeconds, pushInfo.identifier != nil {
            queue.async {
                let currentRunLoop = RunLoop.current
                let timer = Timer.scheduledTimer(timeInterval: livingTime/1000.0, target: NotificationHelper.shared, selector: #selector(NotificationHelper.shared.fireNotificationExpire), userInfo: userInfo, repeats: false)
                currentRunLoop.add(timer, forMode: .common)
                currentRunLoop.run()
            }
        }
        
        //update server
        let analyticAction = pushInfo.command == PushCommand.deviceMetric ? SensorType.AnalyticAction.diagnostic : SensorType.AnalyticAction.notification
            
        let payLoadInfo = PayLoadInfo(action: analyticAction, userInfo: userInfo, userAgent: UserAgent.defaultAgent)
        let acknoledgeRequest = UpdateReadRequest(timeInterval: Date().timeIntervalSince1970, sensor: SensorType.lamp_analytics.lampIdentifier, payLoadInfo: payLoadInfo)
        guard let participantId = User.shared.userId else {
            return
        }
        let lampAPI = NetworkConfig.networkingAPI()
        let endPoint = String(format: Endpoint.participantSensorEvent.rawValue, participantId)
        let data = RequestData(endpoint: endPoint, requestType: HTTPMethodType.post, body: acknoledgeRequest.toJSON())
        lampAPI.makeWebserviceCall(with: data) { (response: Result<EmptyResponse>) in
            completionHandler(UIBackgroundFetchResult.noData)
        }
        
        
        /*
        let payLoadInfo = PayLoadInfo(action: SensorType.AnalyticAction.notification.rawValue, userInfo: userInfo, userAgent: UserAgent.defaultAgent)
        let acknoledgeRequest = UpdateReadRequest(timeInterval: Date().timeIntervalSince1970, sensor: SensorType.lamp_analytics.lampIdentifier, payLoadInfo: payLoadInfo)
        guard let authheader = Endpoint.getSessionKey(), let participantId = User.shared.userId else {
            return
        }
        OpenAPIClientAPI.basePath = LampURL.baseURLString
        OpenAPIClientAPI.customHeaders = ["Authorization": "Basic \(authheader)", "Content-Type": "application/json"]
        let publisher = SensorEventAPI.pushReceiptEventCreate(participantId: participantId, sensorEvent: acknoledgeRequest.toJSON(), apiResponseQueue: DispatchQueue.global())
        subscriber = publisher.sink { _ in
            completionHandler(UIBackgroundFetchResult.noData)
        } receiveValue: { (stringValue) in
            print("login receiveValue = \(stringValue)")
        }*/
        
        calculateBadgeCount()
        LMSensorManager.shared.checkIsRunning()
    }

    // The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction.
    //The delegate must be set before the application returns from applicationDidFinishLaunching:.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Swift.Void) {
        
        calculateBadgeCount()
        guard let remoteAction = RemoteNotification.Action.buildFromIdentifier(response.actionIdentifier) else { return }
        respondedToNotification(remoteAction: remoteAction, userInfo: response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func calculateBadgeCount() {

        UNUserNotificationCenter.current().getDeliveredNotifications { nots in
            // let distinctIdentifiersCount = Set(nots.map({$0.request.identifier})).count
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = nots.count
                UserDefaults.standard.badgeCountShared = nots.count
            }
        }
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
        } else {
            
//            let deliveredTime = UserDefaults.standard.getTimestampForNotificationId(nId: pushInfo.notificationId ?? "")
//            let appdelegate = UIApplication.shared.delegate as! AppDelegate
//            let alert = UIAlertController(title: pushInfo.identifier, message: "\(deliveredTime) + \(pushInfo.expireMilliSeconds)", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "alert.button.ok".localized, style: .destructive, handler: { action in
//               }))
//            appdelegate.window?.rootViewController?.present(alert, animated: true, completion: nil)
            
            switch action {
            case .openAppNoWebView, .openApp, .defaultTap:
                guard let pageURL = pushInfo.pageURLForAction(action) else { break }
                _ = openWebPage(pageURL, title: pushInfo.alert)
            case .dismiss:
                ()
            }
        }
    }
    
    private func openWebPage(_ pageURL: URL, title: String?) -> Bool {
        
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return false }
//        if let contentView = (windowScene.windows[0].rootViewController as? UIHostingController<HomeView>)?.rootView {
//
//            if contentView.viewModel.pushedByNotification == true && contentView.viewModel.notificationPageURL?.absoluteString == pageURL.absoluteString {
//            } else {
//                contentView.viewModel.notificationPageTitle = title
//                contentView.viewModel.notificationPageURL = pageURL
//                contentView.viewModel.pushedByNotification = true
//                return true
//            }
//        }
        
//        let webViewController = WebViewController()
//        if let navController = self.window?.rootViewController as? UINavigationController {
//            if let existiWebController = navController.topViewController as? WebViewController, existiWebController.pageURL.absoluteString ==  pageURL.absoluteString {
//            } else {
//                webViewController.title = title
//                webViewController.pageURL = pageURL
//                navController.pushViewController(webViewController, animated: true)
//                return true
//            }
//        }
        
        if let navController = self.window?.rootViewController as? UINavigationController {
            
            if let existiWebController = navController.topViewController as? HomeViewController {
                //existiWebController.title = title
                //print("pageURL = \(pageURL.absoluteString)")
                existiWebController.tappedActivityURL = pageURL
                // navController.pushViewController(webViewController, animated: true)
                return true
            }
        }
        return false
    }


}
