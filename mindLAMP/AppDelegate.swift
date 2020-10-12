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
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
//        let o = StringHelper(salt: "\(AppDelegate.self.description()), \(NSObject.self.description()), \(NSString.self.description()), \(NSArray.self.description())")
//        let bytes = o.bytesByHelpingString(string: "com.apple"+".springboard.lockcomplete")
//        print(bytes)//[14, 6, 3, 74, 45, 49, 61, 60, 58, 28, 93, 49, 2, 25, 42, 2, 14, 10, 6, 19, 16, 75, 64, 79, 45, 56, 44, 13, 7, 21, 15, 17, 88, 69]
//        let bytes2 = o.bytesByHelpingString(string: "com.apple"+".springboard.lockstate")
//        print(bytes2)//[14, 6, 3, 74, 45, 49, 61, 60, 58, 28, 93, 49, 2, 25, 42, 2, 14, 10, 6, 19, 16, 75, 64, 79, 45, 56, 60, 22, 11, 17, 6]

        // Override point for customization after application launch.
        WatchSessionManager.shared.startSession()
        WatchSessionManager.shared.iOSDelegate = LMSensorManager.shared
        
        NotificationHelper.shared.registerForPushNotifications(delegate: self)
        NotificationHelper.shared.handleLaunchWithRemoteNotification(launchOptions)
        
        let documentsURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        print("documentsURL = \(documentsURL)")
        
        if launchOptions?[UIApplication.LaunchOptionsKey.location] != nil {
            LMSensorManager.shared.checkIsRunning()
        }
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        //BackgroundServices.shared.performTasksInBG(completionHandler: completionHandler)
        LMSensorManager.shared.checkIsRunning()
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        print("handleEventsForBackgroundURLSession")
        completionHandler()
        //self.completionHandler = completionHandler
    }
}

