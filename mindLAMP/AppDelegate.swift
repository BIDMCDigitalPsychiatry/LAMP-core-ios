//
//  AppDelegate.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engg Dept on 02/01/20.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var completionHandler: (() -> Void)?
    var window: UIWindow? //for iOS < 13
    let queue = DispatchQueue(label: "Timer", qos: .background, attributes: .concurrent)
    //var subscriber: AnyCancellable?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        WatchSessionManager.shared.startSession()
        WatchSessionManager.shared.iOSDelegate = LMSensorManager.shared
        
        NotificationHelper.shared.registerForPushNotifications(delegate: self)
        NotificationHelper.shared.handleLaunchWithRemoteNotification(launchOptions)
        
//        let documentsURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
//        print("Launched documentsURL = \(documentsURL) \(Date())")

        UserDefaults.standard.activityAPILastAccessedDate = Date.init(timeIntervalSince1970: 0)// to fetch activity when ever launch app.
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
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

private extension AppDelegate {
    func shareCredentialsToNotificationExtension() {
        if let base64Auth = Endpoint.getSessionKey(), UserDefaults.standard.userIDShared == nil {
            
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

