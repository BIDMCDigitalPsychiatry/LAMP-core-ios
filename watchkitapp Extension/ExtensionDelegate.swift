// watchkitapp Extension

import WatchKit
import UserNotifications
import WatchConnectivity

//https://developer.apple.com/documentation/watchkit/wkapplicationrefreshbackgroundtask
//https://developer.apple.com/documentation/clockkit/creating_and_updating_complications
//https://developer.apple.com/documentation/watchkit/running_watchos_apps_in_the_background
class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    // An array to keep the background tasks.
    //
    private var wcBackgroundTasks = [WKWatchConnectivityRefreshBackgroundTask]()
    //let session = WKExtendedRuntimeSession()//https://developer.apple.com/documentation/watchkit/using_extended_runtime_sessions
    
    func applicationDidFinishLaunching() {
        
        WatchSessionManager.shared.startSession()
        WatchSessionManager.shared.watchOSDelegate = LMSensorManager.shared
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
        let documentsURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        print("documentsURL = \(documentsURL)")
        
        //SensorLogs.shared.printAllFiles()
        
        UserDefaults.standard.setInitalSensorRecorderTimestamp()
        
        LMSensorManager.shared.checkIsRunning()
    }
    
    // Call when the app goes to the background.
    func applicationDidEnterBackground() {
        // Schedule a background refresh task to update the complications.
        scheduleBackgroundRefreshTasks()
        LMSensorManager.shared.sensor_motionManager?.restartMotionUpdates()
        LMSensorManager.shared.sensor_location?.stop()
        LMSensorManager.shared.sensor_location?.start()
    }
    
    func applicationDidBecomeActive() {
        
        LMSensorManager.shared.checkIsRunning()
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //session.invalidate()
        //session.delegate = self   // self as session handler
        //session.start()  // start WKExtendedRuntimeSession
    }
    
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }
    
    // Compelete the background tasks, and schedule a snapshot refresh.
    //
//    func completeBackgroundTasks() {
//        guard !wcBackgroundTasks.isEmpty else { return }
//
//        guard WCSession.default.activationState == .activated,
//            WCSession.default.hasContentPending == false else { return }
//
//        wcBackgroundTasks.forEach { $0.setTaskCompletedWithSnapshot(true) }
//
//        // Schedule a snapshot refresh if the UI is updated by background tasks.
//        //
//        let date = Date(timeIntervalSinceNow: 1)
//        WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: date, userInfo: nil) { error in
//
//            if let error = error {
//                print("scheduleSnapshotRefresh error: \(error)!")
//            }
//        }
//        wcBackgroundTasks.removeAll()
//    }
    
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
//    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
//
//        for task in backgroundTasks {
//            // Use Logger to log the tasks for debug purpose. A real app may remove the log
//            // to save the precious background time.
//            //
//            if let wcTask = task as? WKWatchConnectivityRefreshBackgroundTask {
//                wcBackgroundTasks.append(wcTask)
//            } else {
//                task.setTaskCompletedWithSnapshot(true)
//            }
//        }
//        completeBackgroundTasks()
//    }
//
    // Called when a background task occurs.
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        
        LMSensorManager.shared.checkIsRunning()
        
        for task in backgroundTasks {
            
            switch task {
            // Handle background refresh tasks.
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                
                //on completion //+TODO
                
                // Schedule the next background update.
                self.scheduleBackgroundRefreshTasks()
                
                // Mark the task as ended, and request an updated snapshot.
                backgroundTask.setTaskCompletedWithSnapshot(true)
                
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    // MARK: - Private Methods
    // Schedule the next background refresh task.
    func scheduleBackgroundRefreshTasks() {
        
        // Get the shared extension object.
        let watchExtension = WKExtension.shared()
        
        // If there is a complication on the watch face, the app should get at least four
        // updates an hour. So calculate a target date 15 minutes in the future.
        let targetDate = Date().addingTimeInterval(15.0 * 60.0)
        
        // Schedule the background refresh task.
        watchExtension.scheduleBackgroundRefresh(withPreferredDate: targetDate, userInfo: nil) { (error) in
            // Check for errors.
            if let error = error {
                print("*** An background refresh error occurred: \(error.localizedDescription) ***")
                return
            }
            print("*** Background Task Completed Successfully! ***")
        }
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
            //UserDefaults.standard.logData = "settings.alertSetting = \(settings.alertSetting.rawValue)"
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
            //UserDefaults.standard.logData = "registering"
            WKExtension.shared().registerForRemoteNotifications()
        }
    }
    
    func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
        print("error = \(error.localizedMessage)")
    }
    
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        
        let deviceTokenStr = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("deviceTokenStr = \(deviceTokenStr)")
        //UserDefaults.standard.logData = "deviceTokenStr = \(deviceTokenStr)"
        // Sync to Server and store to userdefault if any change in devicetoken value
        if deviceTokenStr != UserDefaults.standard.deviceToken {
            if User.shared.isLogin() {
                //send to server
                let tokenInfo = DeviceInfoWithToken(deviceToken: deviceTokenStr, userAgent: UserAgent.defaultAgent, action: nil)
                let tokenRerquest = PushNotification.UpdateTokenRequest(deviceInfoWithToken: tokenInfo)
                let lampAPI = NotificationAPI(NetworkConfig.networkingAPI(isBackgroundSession: false))
                
                lampAPI.sendDeviceToken(request: tokenRerquest) { (isSuccess) in
                    if isSuccess {
                        UserDefaults.standard.deviceToken = deviceTokenStr
                    }
                }
            } else {
                UserDefaults.standard.deviceToken = deviceTokenStr
            }
        }
    }
    
    
    /** This delegate method offers an opportunity for applications with the "remote-notification" background mode to fetch appropriate new data in response to an incoming remote notification. You should call the fetchCompletionHandler as soon as you're finished performing that operation, so the system can accurately estimate its power and data cost.
     
     This method will be invoked even if the application was launched or resumed because of the remote background notification.!*/
    func didReceiveRemoteNotification(_ userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (WKBackgroundFetchResult) -> Void) {
        //check notification payload
        print("remote APNS")
        //update server
        let payLoadInfo = PayLoadInfo(userInfo: userInfo, userAgent: UserAgent.defaultAgent)
        let timeStamp = Date().timeIntervalSince1970 * 1000
        let acknoledgeRequest = PushNotification.UpdateReadRequest(timeInterval: timeStamp, payLoadInfo: payLoadInfo)
        let lampAPI = NotificationAPI(NetworkConfig.networkingAPI())
        lampAPI.sendPushAcknowledgement(request: acknoledgeRequest){}
        
        LMSensorManager.shared.checkIsRunning()
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

//https://developer.apple.com/documentation/watchkit/using_extended_runtime_sessions
//extension ExtensionDelegate: WKExtendedRuntimeSessionDelegate {
//    // MARK:- Extended Runtime Session Delegate Methods
//    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
//        // Track when your session starts.
//    }
//
//    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
//        // Finish and clean up any tasks before the session ends.
//    }
//        
//    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
//        // Track when your session ends.
//        // Also handle errors here.
//    }
//}
