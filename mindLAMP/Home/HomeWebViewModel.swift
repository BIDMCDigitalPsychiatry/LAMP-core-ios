//  mindLAMP Consortium

import Foundation
import WebKit
import LAMP
import Combine

enum ScriptMessageHandler: String {
    case login = "login"
    case logout = "logout"
    case allowSpeech = "allowSpeech"
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
    
    var subscriber: AnyCancellable?
    
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
        
        NotificationHelper.shared.removeAllExpiredNotifications()
        
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
        LMSensorManager.shared.checkIsRunning()
        
        //call lamp.analytics for login
        let deviceToken = UserDefaults.standard.deviceToken
        guard let authheader = Endpoint.getSessionKey(), let participantId = User.shared.userId else {
            return
        }
        OpenAPIClientAPI.basePath = LampURL.baseURLString
        OpenAPIClientAPI.customHeaders = ["Authorization": "Basic \(authheader)", "Content-Type": "application/json"]
        let tokenInfo = DeviceInfoWithToken(deviceToken: deviceToken, userAgent: UserAgent.defaultAgent, action: SensorType.AnalyticAction.login.rawValue)
       
        let event = SensorEvent(timestamp: Date().timeInMilliSeconds, sensor: SensorType.lamp_analytics.lampIdentifier, data: tokenInfo)
        let publisher = SensorEventAPI.sensorEventCreate(participantId: participantId, sensorEvent: event, apiResponseQueue: DispatchQueue.global())
        subscriber = publisher.sink { value in
            switch value {
            case .failure(let error):
                printError("loginSensorEventCreate error \(error.localizedDescription)")
            case .finished:
                break
            }
        } receiveValue: { (stringValue) in
            print("login receiveValue = \(stringValue)")
        }
    }
    
    func performOnLogout() {
        
        //send lamp.analytics for logout
        guard let authheader = Endpoint.getSessionKey(), let participantId = User.shared.userId else {
            NotificationHelper.shared.removeAllNotifications()
            User.shared.logout()
            return
        }
        OpenAPIClientAPI.basePath = LampURL.baseURLString
        OpenAPIClientAPI.customHeaders = ["Authorization": "Basic \(authheader)", "Content-Type": "application/json"]
        let tokenInfo = DeviceInfoWithToken(deviceToken: nil, userAgent: UserAgent.defaultAgent, action: SensorType.AnalyticAction.logout.rawValue)
        let event = SensorEvent(timestamp: Date().timeInMilliSeconds, sensor: SensorType.lamp_analytics.lampIdentifier, data: tokenInfo)
        let publisher = SensorEventAPI.sensorEventCreate(participantId: participantId, sensorEvent: event, apiResponseQueue: DispatchQueue.global())
        subscriber = publisher.sink { _ in
            NotificationHelper.shared.removeAllNotifications()
            User.shared.logout()
        } receiveValue: { (stringValue) in
            print("login receiveValue = \(stringValue)")
        }
    }
}
