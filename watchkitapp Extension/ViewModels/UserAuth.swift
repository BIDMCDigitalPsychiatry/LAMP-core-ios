// watchkitapp Extension

import Combine
import Foundation
import WatchKit

class UserAuth: ObservableObject {
    
    enum Status {
        case logout
        case loginInput
        case serverURLInput
        case loggedIn
    }
    var serverURLDomain: String = LampURL.lampAPI.cleanHostName()
    var userName: String?//
    var password: String?//
    
    var serverURLDomainDisplayValue: String {
        return serverURLDomain.isEmpty ? LampURL.lampAPI.cleanHostName() : serverURLDomain
    }
    
    var serverURL: String {
        return "https://" + serverURLDomainDisplayValue
    }
    
    var errorMsg: String?
    var loginStatus: Status = .logout {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    func startLogin() {
        loginStatus = .loginInput
    }
    
    func showServerURL() {
        loginStatus = .serverURLInput
    }
    
    func backToLoginEdit() {
        loginStatus = .loginInput
    }
    
    let objectWillChange = ObservableObjectPublisher()
    
    init(_ isLoggedIn: Bool) {
        if isLoggedIn {
            self.loginStatus = .loggedIn
            LMWatchSensorManager.shared.checkIsRunning()
        } else {
            self.loginStatus = .logout
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).userLogined(_:)),
            name: .userLogined, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).userLogOut(_:)),
            name: .userLogOut, object: nil
        )
    }
    // .login notification handler. Update the UI the notification object.
    //
    @objc func userLogined(_ notification: Notification) {
        print("received notification")
        self.loginStatus = Status.loggedIn
        WKExtension.shared().registerForRemoteNotifications()
    }
    
    // .login notification handler. Update the UI the notification object.
    //
    @objc func userLogOut(_ notification: Notification) {
        print("received notification")
        self.loginStatus = .logout
    }
    
    func logout() {
        self.loginStatus = .logout
        User.shared.logout()
    }
    
    //let didChange = PassthroughSubject<UserAuth,Never>()
    
    // required to conform to protocol 'ObservableObject'
    //let willChange = PassthroughSubject<UserAuth,Never>()
    func login(userName: String, password: String, completion: ((Bool) -> Void)? ) {
        
        let base64 = Data("\(userName):\(password)".utf8).base64EncodedString()
        Endpoint.setSessionKey(base64)
        let lampAPI = LoginAPI(NetworkConfig.networkingAPI(urlString: self.serverURL))
        lampAPI.getParticipant(userID: userName) { [weak self] (isSuccess, userInfo, error) in
            guard let self = self else { return }
            self.errorMsg = error?.localizedMessage
            if isSuccess {
                let userID = userInfo?.id ??  userName//idObjectDict?["id"] as? String
                User.shared.login(userID: userID, serverAddress: self.serverURL)
                self.loginStatus = .loggedIn
                self.sendToken()
                DispatchQueue.main.async {
                    Utils.postNotificationOnMainQueueAsync(name: .userLogined)
                }
                LMWatchSensorManager.shared.checkIsRunning()
            } else {
                self.loginStatus = .loginInput
            }
            DispatchQueue.main.async {
                completion?(self.errorMsg == nil)
            }

        }
    }
    
    //    @Published var isLoggedin: Bool {
    //        didSet {
    //            didChange.send(self)
    //        }
    //
    //        // willSet {
    //        //       willChange.send(self)
    //        // }
    //    }
    
    func sendToken() {
//
//        guard let deviceToken = UserDefaults.standard.watchdeviceToken else { return }
//        let tokenInfo = DeviceInfoWithToken(deviceToken: deviceToken, userAgent: UserAgent.defaultAgent)
//        let tokenRerquest = PushNotification.UpdateTokenRequest(deviceInfoWithToken: tokenInfo)
//        let lampAPI = NotificationAPI(NetworkConfig.networkingAPI(isBackgroundSession: true))
//
//        lampAPI.sendDeviceToken(request: tokenRerquest) { (isSuccess) in
//            print("sent device token \(isSuccess)")
//        }
//
//
        let deviceTokenStr = UserDefaults.standard.deviceToken
        let tokenInfo = DeviceInfoWithToken(deviceToken: deviceTokenStr, userAgent: UserAgent.defaultAgent)
        let tokenRerquest = PushNotification.UpdateTokenRequest(deviceInfoWithToken: tokenInfo)
        let lampAPI = NotificationAPI(NetworkConfig.networkingAPI(isBackgroundSession: false))
        
        lampAPI.sendDeviceToken(request: tokenRerquest) { (isSuccess) in
            if isSuccess {
                print("sent device token \(isSuccess)")
            } else {
            }
        }
    }
}
