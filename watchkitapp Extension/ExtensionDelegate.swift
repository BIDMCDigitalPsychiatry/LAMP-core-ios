// watchkitapp Extension

import WatchKit
import UserNotifications
import WatchConnectivity
import LAMP
import Combine

class ExtensionDelegate: NSObject, WKApplicationDelegate {
    
    // An array to keep the background tasks.
    //
    private var wcBackgroundTasks = [WKWatchConnectivityRefreshBackgroundTask]()
    private var subscriber: AnyCancellable?
    
    func applicationDidFinishLaunching() {
        
        WatchSessionManager.shared.startSession()
        WatchSessionManager.shared.watchOSDelegate = LMSensorManager.shared
        print("start APNS")
        // Perform any final initialization of your application.
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] (granted, error) in
            guard granted else {
                //print("not granted APNS \(error?.localizedMessage)")
                self?.getNotificationSettings()
                return }
            print("granted APNS")
            self?.getNotificationSettings()
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
    }
    
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }
    
    // Called when a background task occurs.
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        
        LMSensorManager.shared.checkIsRunning()
        
        for task in backgroundTasks {
            
            switch task {
            // Handle background refresh tasks.
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                
                // Schedule the next background update.
                scheduleBackgroundRefreshTasks()
                
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
        let watchExtension = WKApplication.shared()
        
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
        if WKApplication.shared().isRegisteredForRemoteNotifications == true {
            print("registered")
        }
        if User.shared.isLogin() == false {
            WKApplication.shared().unregisterForRemoteNotifications()
        } else {
            print("registering")
            //UserDefaults.standard.logData = "registering"
            WKApplication.shared().registerForRemoteNotifications()
        }
    }
    
    func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
        print("Notification error = \(error.localizedDescription)")
    }
    
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        
        let deviceTokenStr = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("deviceTokenStr = \(deviceTokenStr)")
        //UserDefaults.standard.logData = "deviceTokenStr = \(deviceTokenStr)"
        // Sync to Server and store to userdefault if any change in devicetoken value
        if deviceTokenStr != UserDefaults.standard.deviceToken {
            if User.shared.isLogin() {
                //send to server
                guard let authheader = Endpoint.getAuthHeader(), let participantId = User.shared.userId else {
                    return
                }
                OpenAPIClientAPI.basePath = LampURL.baseURLString
                OpenAPIClientAPI.customHeaders = ["Authorization": authheader, "Content-Type": "application/json"]
                let tokenInfo = DeviceInfoWithToken(deviceToken: deviceTokenStr, userAgent: UserAgent.defaultAgent, action: nil)
               
                let event = SensorEvent(timestamp: Date().timeInMilliSeconds, sensor: SensorType.lamp_analytics.lampIdentifier, data: tokenInfo)
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
        let payLoadInfo = PayLoadInfo(action: SensorType.AnalyticAction.notification, userInfo: userInfo, userAgent: UserAgent.defaultAgent)
        let timeStamp = Date().timeIntervalSince1970
        let acknoledgeRequest = UpdateReadRequest(timeInterval: timeStamp, sensor: SensorType.lamp_analytics.lampIdentifier, payLoadInfo: payLoadInfo)
        guard let authheader = Endpoint.getAuthHeader(), let participantId = User.shared.userId else {
            return
        }
        OpenAPIClientAPI.basePath = LampURL.baseURLString
        OpenAPIClientAPI.customHeaders = ["Authorization": authheader, "Content-Type": "application/json"]
        let publisher = SensorEventAPI.pushReceiptEventCreate(participantId: participantId, sensorEvent: acknoledgeRequest.toJSON(), apiResponseQueue: DispatchQueue.global())
        subscriber = publisher.sink {_ in } receiveValue: {_ in }
        LMSensorManager.shared.checkIsRunning()
    }
}

extension ExtensionDelegate: UNUserNotificationCenterDelegate {
    // The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        print("remote APNS")
        completionHandler([.banner, .badge, .sound])
    }
    
    
    // The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from application:didFinishLaunchingWithOptions:.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void){
        print("remote APNS")
        completionHandler()
    }
    
}
