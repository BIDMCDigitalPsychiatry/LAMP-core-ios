// watchkitapp Extension

import Foundation

extension LMSensorManager: WatchOSDelegate {
    
    func messageReceived(tuple: MessageReceived) {
    }
    
    func applicationContextReceived(tuple: ApplicationContextReceived) {
        
        DispatchQueue.main.async() {
            if let loginDict = tuple.applicationContext[IOSCommands.login] as? [String: Any] {
                let loginInfo = LoginInfo(loginDict)
                Endpoint.setSessionKey(loginInfo.sessionToken)
                User.shared.login(userID: loginInfo.userId, serverAddress: loginInfo.serverAddress)
                Utils.postNotificationOnMainQueueAsync(name: .userLogined)
                LMSensorManager.shared.checkIsRunning()
            } else if let _ = tuple.applicationContext[IOSCommands.sendWatchSensorEvents] as? Bool {
                //LMWatchSensorManager.shared.sendSensorEvents()
                LMSensorManager.shared.checkIsRunning()
            } else if let _ = tuple.applicationContext[IOSCommands.logout] as? Bool {
//                let isLoginPreviously = User.shared.isLogin()
                User.shared.logout()
                Utils.postNotificationOnMainQueueAsync(name: .userLogOut)
//                if isLoginPreviously {
//                    WKApplication.shared().unregisterForRemoteNotifications()
//                }
            }
        }
    }
}
