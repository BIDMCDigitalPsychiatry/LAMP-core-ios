// watchkitapp Extension
//https://stackoverflow.com/questions/58094221/failing-apns-for-independent-watchos6-app

import WatchKit
import UserNotifications
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    var connectivityHandler = WatchSessionManager.shared
    var session : WCSession?

    func applicationDidFinishLaunching() {
        
        print("extension launched")
        connectivityHandler.startSession()
        connectivityHandler.watchOSDelegate = self
        // Perform any final initialization of your application.
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {(granted, _ ) in
            guard granted else { return }
            self.getNotificationSettings()
        }
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

}

extension ExtensionDelegate {
    
    private func getNotificationSettings() {

        UNUserNotificationCenter.current().getNotificationSettings { settings in

            guard settings.authorizationStatus == .authorized else { return }
            UNUserNotificationCenter.current().delegate = self
            DispatchQueue.main.async {
                WKExtension.shared().registerForRemoteNotifications()
            }
        }
    }
    
    func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
        
    }
    
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
    
        let deviceTokenStr = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("deviceTokenStr = \(deviceTokenStr)")
        // Sync to Server and store to userdefault if any change in devicetoken value
        if deviceTokenStr != UserDefaults.standard.watchdeviceToken {
            if User.shared.isLogin() {
                //send to server
                let tokenInfo = WatchInfoWithToken(deviceToken: deviceTokenStr)
                let tokenRerquest = WatchNotification.UpdateTokenRequest(deviceInfoWithToken: tokenInfo)
                let lampAPI = NotificationAPI(NetworkConfig.networkingAPI(isBackgroundSession: true))
                
                lampAPI.sendDeviceToken(request: tokenRerquest) { (isSuccess) in
                    if isSuccess {
                        UserDefaults.standard.watchdeviceToken = deviceTokenStr
                    }
                }
            } else {
                UserDefaults.standard.watchdeviceToken = deviceTokenStr
            }
        }
    }
    
    /** This delegate method offers an opportunity for applications with the "remote-notification" background mode to fetch appropriate new data in response to an incoming remote notification. You should call the fetchCompletionHandler as soon as you're finished performing that operation, so the system can accurately estimate its power and data cost.

     This method will be invoked even if the application was launched or resumed because of the remote background notification.!*/
    func didReceiveRemoteNotification(_ userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (WKBackgroundFetchResult) -> Void) {
        //check notification payload
        
    }
}

extension ExtensionDelegate: UNUserNotificationCenterDelegate {
    // The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        let senosrManager = LMWatchSensorManager.shared
        senosrManager.startUpdates()
        
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(sendSensorEventsToServer), userInfo: nil, repeats: false)
    }

    
    // The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from application:didFinishLaunchingWithOptions:.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void){
        
    }
    
    @objc func sendSensorEventsToServer() {
        LMWatchSensorManager.shared.stopUpdates(isSendToPhone: false)
        SensorEvents().postSensorData()
    }
    @objc func sendSensorEventsToPhone() {
        LMWatchSensorManager.shared.stopUpdates(isSendToPhone: true)
    }
}

extension ExtensionDelegate: WatchOSDelegate {
    
    func messageReceived(tuple: MessageReceived) {
        DispatchQueue.main.async() {
            //WKInterfaceDevice.current().play(.notification)
            if let id = tuple.message[SharingInfo.Keys.userId.rawValue] as? String, let sessionToken = tuple.message[SharingInfo.Keys.sessionToken.rawValue] as? String{
                Endpoint.setSessionKey(sessionToken)
                UserDefaults.standard.set(true, forKey: "islogged")
                User.shared.login(userID: id, serverAddress: nil)
                
                self.postNotificationOnMainQueueAsync(name: .userLogined)
            } else if let _ = tuple.message[SharingInfo.Keys.fetchWatchSensorEvents.rawValue] as? Bool {
                
                LMWatchSensorManager.shared.startUpdates()
                Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.sendSensorEventsToPhone), userInfo: nil, repeats: false)
            }
        }
    }
    
    private func postNotificationOnMainQueueAsync(name: NSNotification.Name) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: nil)
        }
    }
}
