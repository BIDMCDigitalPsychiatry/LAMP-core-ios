//
//  AppDelegate.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engg Dept on 02/01/20.
//

import UIKit
import WidgetKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var completionHandler: (() -> Void)?
    var window: UIWindow? //for iOS < 13
    let queue = DispatchQueue(label: "Timer", qos: .background, attributes: .concurrent)
    //var subscriber: AnyCancellable?
    private var widgetHelper = StreakWidgetHelper()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Logging.isLogToFile = true
        // Override point for customization after application launch.
        WatchSessionManager.shared.startSession()
        WatchSessionManager.shared.iOSDelegate = LMSensorManager.shared
        
        NotificationHelper.shared.registerForPushNotifications(delegate: self)
        NotificationHelper.shared.handleLaunchWithRemoteNotification(launchOptions)
        
//        let documentsURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
//        print("Launched documentsURL = \(documentsURL) \(Date())")

        UserDefaults.standard.activityAPILastAccessedDate = Date.init(timeIntervalSince1970: 0)// to fetch activity when ever launch app.
        UserDefaults.standard.activityAPILastScheduledDate = Date.init(timeIntervalSince1970: 0)
        LMSensorManager.shared.checkIsRunning()

        //Version 1.1.3 Build 70. backward compatibility for already logined users
        shareCredentialsToNotificationExtension()
        
        //+for ViewController support
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let homeVC = HomeViewController()
        self.window?.rootViewController = UINavigationController(rootViewController: homeVC)
        self.window?.makeKeyAndVisible()

        return true
    }
 
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        LMSensorManager.shared.checkIsRunning()
        completionHandler(UIBackgroundFetchResult.noData)
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        calculateBadgeCount()
    }
    func applicationDidEnterBackground(_ application: UIApplication) {
        UIApplication.shared.isIdleTimerDisabled = false
        calculateBadgeCount()
    }
    func applicationWillResignActive(_ application: UIApplication) {
        refreshStreakWidget()
    }
    
    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {

        if userActivityType == "StreakWidget" {
            if let navController = self.window?.rootViewController as? UINavigationController {
                
                if let existiWebController = navController.topViewController as? HomeViewController {
                    existiWebController.tappedWidget()
                    return true
                }
            }
        }
        return true
    }
}

private extension AppDelegate {
    /// Saves the streak for the widget, fetched with the app's own login (the
    /// widget never calls the server). On any failure the saved streak stays
    func refreshStreakWidget() {
        guard User.shared.isLogin(), let participantId = User.shared.userId else {
            // Logged out: logout already cleared the saved streak
            WidgetCenter.shared.reloadAllTimelines()
            return
        }
        // Lets the request finish while the app goes to the background
        let application = UIApplication.shared
        var backgroundTask = UIBackgroundTaskIdentifier.invalid
        let endBackgroundTask = {
            guard backgroundTask != .invalid else { return }
            application.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        backgroundTask = application.beginBackgroundTask(expirationHandler: endBackgroundTask)

        let helper = widgetHelper
        let from = Int64(helper.fetchStartDate(participantId: participantId).timeInMilliSeconds)
        let request = RequestData(endpoint: String(format: Endpoint.activityEvent.rawValue, participantId),
                                  requestType: .get, endpointDetails: "?from=\(from)")
        NetworkConfig.networkingAPI().makeWebserviceCall(with: request) { (response: Result<StreakWidgetHelper.ActivityEventResponse>) in
            DispatchQueue.main.async {
                // Skip if the participant logged out while the request was out
                if case .success(let events) = response, let dates = events.dates, User.shared.userId == participantId {
                    helper.saveStreak(dates: dates, participantId: participantId)
                    WidgetCenter.shared.reloadAllTimelines()
                }
                endBackgroundTask()
            }
        }
    }

    func shareCredentialsToNotificationExtension() {
        // Token users: remove a password copy kept by an earlier test build's upgrade
        if Endpoint.isBearerSession {
            UserDefaults.standard.userIDShared = nil
            UserDefaults.standard.passwordShared = nil
            return
        }
        if let base64Auth = Endpoint.getBase64BasicAuth(), UserDefaults.standard.userIDShared == nil {
            
            guard let decodedData = Data(base64Encoded: base64Auth), let decodedString = String(data: decodedData, encoding: .utf8) else {
                return
            }
            let (username, password) = decodedString.makeTwoPiecesUsing(seperator: ":")
            UserDefaults.standard.userIDShared = username
            UserDefaults.standard.passwordShared = password
            UserDefaults.standard.serverAddressShared = UserDefaults.standard.serverAddress?.cleanHostName()
        }
    }
}

