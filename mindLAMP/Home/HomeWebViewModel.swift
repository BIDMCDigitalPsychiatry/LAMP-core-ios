//  mindLAMP Consortium

import Foundation
import WebKit

enum ScriptMessageHandler: String {
    case login = "login"
    case logout = "logout"
}

enum ScriptMessageKey: String {
    case authorizationToken = "authorizationToken"
    case identityObject = "identityObject"
    case serverAddress = "serverAddress"
}

class WebViewStorage {
    static let shared = WebViewStorage()
    let processPool = WKProcessPool()
    let dataStore = WKWebsiteDataStore.default()
}

class HomeWebViewModel: NSObject, ObservableObject {
    
    @Published var shouldAnimate = true
    @Published var pushedByNotification = false
    @Published var shouldReload = false
    
    var notificationPageTitle: String?
    var notificationPageURL: URL?
    var isWebpageLoaded: Bool = false
    
    var homeURL: URL {
        if User.shared.isLogin() == true {
            return lampDashboardURLwithToken
        } else {
            return LampURL.dashboardDigital
        }
    }
    
    private var lampDashboardURLwithToken: URL {
        let urlString = LampURL.dashboardDigitalURLText
        if let base64token = Endpoint.getURLToken() {
            return URL(string: urlString + "?a=" + base64token)!
        }
        return LampURL.dashboardDigital
    }
    @objc
    func updateWatchOS(_ notification: Notification) {
        
        if isWebpageLoaded == false {
            isWebpageLoaded = true
            shouldReload = true
        }
        
        if User.shared.isLogin() == true, let loginInfo = User.shared.loginInfo {
            let messageInfo: [String: Any] = [IOSCommands.login : loginInfo, "timestamp" : Date().timeInMilliSeconds]
            WatchSessionManager.shared.updateApplicationContext(applicationContext: messageInfo)
        } else {
            let messageInfo: [String: Any] = [IOSCommands.logout : true]
            WatchSessionManager.shared.updateApplicationContext(applicationContext: messageInfo)
        }
    }
    
//    deinit {
//        wkWebView.stopLoading()
//        wkWebView.configuration.userContentController.removeScriptMessageHandler(forName: ScriptMessageHandler.login.rawValue)
//        wkWebView.configuration.userContentController.removeScriptMessageHandler(forName: ScriptMessageHandler.logout.rawValue)
//    }
}

extension HomeWebViewModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == ScriptMessageHandler.login.rawValue {
            guard let dictBody = message.body as? [String: Any] else {
                printError("Message body not in expected format.")
                return
            }
            print("dictBody = \(dictBody)\n")
            //read token. it will be inthe format of UserName:Password
            guard let token = (dictBody[ScriptMessageKey.authorizationToken.rawValue] as? String),
                let idObjectDict = dictBody[ScriptMessageKey.identityObject.rawValue] as? [String: Any],
                let userID = idObjectDict["id"] as? String  else { return }
            
            let serverAddress = dictBody[ScriptMessageKey.serverAddress.rawValue] as? String
            
            let base64Token = token.data(using: .utf8)?.base64EncodedString()
            Endpoint.setSessionKey(base64Token)
            
            let serverAddressValue = serverAddress ?? ""
            
            let withOutHttp = serverAddressValue.cleanHostName()

            //store url token to load dashboarn on next launch
            let uRLToken = "\(token):\(withOutHttp)"//UserName:Password:ServerAddress
            let base64URLToken = uRLToken.data(using: .utf8)?.base64EncodedString()
            Endpoint.setURLToken(base64URLToken)

            let (username, password) = token.makeTwoPiecesUsing(seperator: ":")
            User.shared.login(userID: userID, username: username, password: password, serverAddress: serverAddress)
            
            //Inform watch the login info
            if let dictInfo = User.shared.loginInfo {
                let messageInfo: [String: Any] = [IOSCommands.login: dictInfo, "timestamp" : Date().timeInMilliSeconds]
                WatchSessionManager.shared.updateApplicationContext(applicationContext: messageInfo)
            }
            performOnLogin()
        } else if message.name == ScriptMessageHandler.logout.rawValue {
            let messageInfo: [String: Any] = [IOSCommands.logout: true, "timestamp" : Date().timeInMilliSeconds]
            WatchSessionManager.shared.updateApplicationContext(applicationContext: messageInfo)
            performOnLogout()
        }
    }
    
    func performOnLogin() {
        printToFile("\nperformOnLogin")
        LMSensorManager.shared.checkIsRunning()
        
        //call lamp.analytics for login
        let deviceToken = UserDefaults.standard.deviceToken
        
        let tokenInfo = DeviceInfoWithToken(deviceToken: deviceToken, userAgent: UserAgent.defaultAgent, action: SensorType.AnalyticAction.login.rawValue)
        let tokenRerquest = PushNotification.UpdateTokenRequest(deviceInfoWithToken: tokenInfo)
        let lampAPI = NotificationAPI(NetworkConfig.networkingAPI())
        
        lampAPI.sendDeviceToken(request: tokenRerquest) {_ in }
    }
    
    func performOnLogout() {
        
        //send lamp.analytics for logout
        let tokenInfo = DeviceInfoWithToken(deviceToken: nil, userAgent: UserAgent.defaultAgent, action: SensorType.AnalyticAction.logout.rawValue)
        let tokenRerquest = PushNotification.UpdateTokenRequest(deviceInfoWithToken: tokenInfo)
        let lampAPI = NotificationAPI(NetworkConfig.networkingAPI())
        
        lampAPI.sendDeviceToken(request: tokenRerquest) {_ in
            NotificationHelper.shared.removeAllNotifications()
            User.shared.logout()
        }
    }
}
