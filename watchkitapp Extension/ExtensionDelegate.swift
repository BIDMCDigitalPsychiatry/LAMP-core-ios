// watchkitapp Extension
//https://stackoverflow.com/questions/58094221/failing-apns-for-independent-watchos6-app

import WatchKit
import UserNotifications
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    // An array to keep the background tasks.
    //
    private var wcBackgroundTasks = [WKWatchConnectivityRefreshBackgroundTask]()
    
    func applicationDidFinishLaunching() {
        
        WatchSessionManager.shared.startSession()
        WatchSessionManager.shared.watchOSDelegate = LMWatchSensorManager.shared
        print("start APNS")
        // Perform any final initialization of your application.
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) {(granted, error ) in
            guard granted else {
                //print("not granted APNS \(error?.localizedMessage)")
                self.getNotificationSettings()
                return }
            print("granted APNS")
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
    
    // Compelete the background tasks, and schedule a snapshot refresh.
    //
    func completeBackgroundTasks() {
        guard !wcBackgroundTasks.isEmpty else { return }
        
        guard WCSession.default.activationState == .activated,
            WCSession.default.hasContentPending == false else { return }
        
        wcBackgroundTasks.forEach { $0.setTaskCompletedWithSnapshot(true) }
        
        // Schedule a snapshot refresh if the UI is updated by background tasks.
        //
        let date = Date(timeIntervalSinceNow: 1)
        WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: date, userInfo: nil) { error in
            
            if let error = error {
                print("scheduleSnapshotRefresh error: \(error)!")
            }
        }
        wcBackgroundTasks.removeAll()
    }
    
    // Be sure to complete all the tasks - otherwise they will keep consuming the background executing
    // time until the time is out of budget and the app is killed.
    //
    // WKWatchConnectivityRefreshBackgroundTask should be completed after the pending data is received
    // so retain the tasks first. The retained tasks will be completed at the following cases:
    // 1. hasContentPending flips to false, meaning all the pending data is received. Pending data means
    //    the data received by the device prior to the WCSession getting activated.
    //    More data might arrive, but it isn't pending when the session activated.
    // 2. The end of the handle method.
    //    This happens when hasContentPending can flip to false before the tasks are retained.
    //
    // If the tasks are completed before the WCSessionDelegate methods are called, the data will be delivered
    // the app is running next time, so no data lost.
    //
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        
        LMWatchSensorManager.shared.sendSensorEvents()
        for task in backgroundTasks {
            // Use Logger to log the tasks for debug purpose. A real app may remove the log
            // to save the precious background time.
            //
            if let wcTask = task as? WKWatchConnectivityRefreshBackgroundTask {
                wcBackgroundTasks.append(wcTask)
            } else {
                task.setTaskCompletedWithSnapshot(true)
            }
        }
        completeBackgroundTasks()
    }
    
}

extension ExtensionDelegate {
    
    private func getNotificationSettings() {
        
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            
            switch settings.authorizationStatus {
                
            case .notDetermined:
                print("not determined")
            case .denied:
                print("denied")
            case .authorized:
                print("authorized")
            case .provisional:
                print("provisional")
            @unknown default:
                ()
            }
            print("settings.alertSetting = \(settings.alertSetting.rawValue)")
        }
        
        //guard settings.authorizationStatus == .authorized else { return }
        UNUserNotificationCenter.current().delegate = self
        if WKExtension.shared().isRegisteredForRemoteNotifications == true {
            print("registered")
        }
        if User.shared.isLogin() == false {
            WKExtension.shared().unregisterForRemoteNotifications()
        } else {
            print("registering")
            WKExtension.shared().registerForRemoteNotifications()
        }
    }
    
    func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
        print("error = \(error.localizedMessage)")
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
                let lampAPI = NotificationAPI(NetworkConfig.networkingAPI(isBackgroundSession: false))
                
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
        print("remote APNS")
        LMWatchSensorManager.shared.sendSensorEvents(completionHandler)
    }
}

extension ExtensionDelegate: UNUserNotificationCenterDelegate {
    // The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        print("remote APNS")
        completionHandler([.alert, .badge, .sound])
    }
    
    
    // The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from application:didFinishLaunchingWithOptions:.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void){
        print("remote APNS")
        completionHandler()
    }
}


