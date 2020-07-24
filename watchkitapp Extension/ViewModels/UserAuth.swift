// watchkitapp Extension

import Combine
import Foundation
import WatchKit
//import SwiftUI

class UserAuth: ObservableObject {
    
    var errorMsg: String?
    var isLoggedin: Bool = false {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    let objectWillChange = ObservableObjectPublisher()
    
    init(_ isLoggedIn: Bool) {
        self.isLoggedin = isLoggedIn
        
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
    @objc
    func userLogined(_ notification: Notification) {
        print("received notification")
        self.isLoggedin = true
        WKExtension.shared().registerForRemoteNotifications()
    }
    // .login notification handler. Update the UI the notification object.
    //
    @objc
    func userLogOut(_ notification: Notification) {
        print("received notification")
        self.isLoggedin = false
        
    }
    //let didChange = PassthroughSubject<UserAuth,Never>()
    
    // required to conform to protocol 'ObservableObject'
    //let willChange = PassthroughSubject<UserAuth,Never>()

    func login(userName: String, password: String, completion: ((Bool) -> Void)? ) {
        
        let base64 = Data("\(userName):\(password)".utf8).base64EncodedString()
        Endpoint.setSessionKey(base64)
        let lampAPI = ParticipantAPI(NetworkConfig.networkingAPI(isBackgroundSession: false))
        
        lampAPI.getParticipant(userID: userName) { [weak self] (isSuccess, userInfo, error) in
            
            self?.errorMsg = error?.localizedMessage
            if isSuccess {
                let userID = userInfo?.id ??  userName//idObjectDict?["id"] as? String
                User.shared.login(userID: userID, serverAddress: nil)
                self?.isLoggedin = true
                self?.sendToken()
            } else {
                self?.isLoggedin = false
            }
            DispatchQueue.main.async {
                completion?(self?.errorMsg == nil)
                Utils.postNotificationOnMainQueueAsync(name: .userLogined)
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
        
        guard let deviceToken = UserDefaults.standard.watchdeviceToken else { return }
        let tokenInfo = WatchInfoWithToken(deviceToken: deviceToken)
        let tokenRerquest = WatchNotification.UpdateTokenRequest(deviceInfoWithToken: tokenInfo)
        let lampAPI = NotificationAPI(NetworkConfig.networkingAPI(isBackgroundSession: true))
        
        lampAPI.sendDeviceToken(request: tokenRerquest) { (isSuccess) in
            print("sent device token \(isSuccess)")
        }
    }
}
