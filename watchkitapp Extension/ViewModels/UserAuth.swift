// watchkitapp Extension

import Combine
import Foundation
import WatchKit
import LAMP

class UserAuth: ObservableObject {
    
    enum Status {
        case logout
        case loginInput
        case serverURLInput
        case loggedIn
    }
    var serverURLDomain: String = LampURL.OpenAPIClientAPI.cleanHostName()
    var userName: String?
    var password: String?
    var subscriber: AnyCancellable?
    
    @Published var shouldAnimate = false
    
    var serverURLDomainDisplayValue: String {
        return serverURLDomain.isEmpty ? LampURL.OpenAPIClientAPI.cleanHostName() : serverURLDomain
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
            LMSensorManager.shared.checkIsRunning()
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
        User.shared.logout()
    }
    
    func logout() {
        
        self.loginStatus = .logout
        
        guard let authheader = Endpoint.getSessionKey(), let participantId = User.shared.userId else {
            User.shared.logout()
            return
        }
        OpenAPIClientAPI.basePath = LampURL.baseURLString
        OpenAPIClientAPI.customHeaders = ["Authorization": "Basic \(authheader)", "Content-Type": "application/json"]
        
        let tokenInfo = DeviceInfoWithToken(deviceToken: nil, userAgent: UserAgent.defaultAgent, action: SensorType.AnalyticAction.logout.rawValue)
        let event = SensorEvent(timestamp: Date().timeInMilliSeconds, sensor: SensorType.lamp_analytics.lampIdentifier, data: tokenInfo)
        let publisher = SensorEventAPI.sensorEventCreate(participantId: participantId, sensorEvent: event, apiResponseQueue: DispatchQueue.global())
        subscriber = publisher.sink { _ in
            User.shared.logout()
        } receiveValue: { (stringValue) in
            print("login receiveValue = \(stringValue)")
        }
       
    }

    private var cancellable: AnyCancellable?
    //let didChange = PassthroughSubject<UserAuth,Never>()
    
    // required to conform to protocol 'ObservableObject'
    //let willChange = PassthroughSubject<UserAuth,Never>()
    func login(userName: String, password: String, completion: ((Bool) -> Void)? ) {
       
        self.shouldAnimate = true
        let base64 = Data("\(userName):\(password)".utf8).base64EncodedString()
        Endpoint.setSessionKey(base64)
        
        //+202012
        OpenAPIClientAPI.basePath = LampURL.baseURLString
        OpenAPIClientAPI.customHeaders = ["Authorization": "Basic \(base64)", "Content-Type": "application/json"]
        
        let publisher = ParticipantAPI.participantView(participantId: "me")
            
            //.map { response in
            //response.data.first
        //}
        subscriber = publisher.sink(receiveCompletion: { [weak self] value in
            guard let self = self else { return }
            print("value = \(value)")
            switch value {
            case .failure(let ErrorResponse.error(code, data, error)):
                printError("login error code\(code), \(error.localizedDescription)")
                var msg: String?
                if let data = data {
                    let decoder = JSONDecoder()
                    do {
                        let errResponse = try decoder.decode(ErrResponse.self, from: data)
                        msg = errResponse.error
                    } catch let err {
                        printError("err = \(err.localizedDescription)")
                    }
                }
                //self.errorMsg = HTTPURLResponse.localizedString(forStatusCode: code)
                self.errorMsg = msg ?? error.localizedDescription
                self.loginStatus = .loginInput
            case .failure(let error):
                self.errorMsg = error.localizedDescription
                self.loginStatus = .loginInput
            case .finished:
                break
            }
            self.shouldAnimate = false
            completion?(self.errorMsg == nil)
        }, receiveValue: { [weak self] response in
            guard let self = self else { return }
            guard let userId = response.data.first?.id else {
                print("no data")
                return}
            User.shared.login(userID: userId, serverAddress: self.serverURL)
            self.loginStatus = .loggedIn
            self.sendLoginInfo()
            Utils.postNotificationOnMainQueueAsync(name: .userLogined)
            LMSensorManager.shared.checkIsRunning()
        })
        //self.cancellable?.cancel()


//
//        let OpenAPIClientAPI = LoginAPI(NetworkConfig.networkingAPI(urlString: self.serverURL))
//        OpenAPIClientAPI.getParticipant(userID: userName) { [weak self] (isSuccess, userInfo, error) in
//            guard let self = self else { return }
//            self.errorMsg = error?.localizedMessage
//            if isSuccess {
//                let userID = userInfo?.id ??  userName//idObjectDict?["id"] as? String
//                User.shared.login(userID: userID, serverAddress: self.serverURL)
//                self.loginStatus = .loggedIn
//                self.sendLoginInfo()
//                DispatchQueue.main.async {
//                    Utils.postNotificationOnMainQueueAsync(name: .userLogined)
//                }
//                LMSensorManager.shared.checkIsRunning()
//            } else {
//                self.loginStatus = .loginInput
//            }
//            DispatchQueue.main.async {
//                completion?(self.errorMsg == nil)
//            }
//
//        }
    }

    func sendLoginInfo() {
        
        let deviceTokenStr = UserDefaults.standard.deviceToken
        let tokenInfo = DeviceInfoWithToken(deviceToken: deviceTokenStr, userAgent: UserAgent.defaultAgent, action: SensorType.AnalyticAction.login.rawValue)
        sendInfoToServer(tokenInfo: tokenInfo)
    }

    func sendInfoToServer(tokenInfo: DeviceInfoWithToken) {
        
        guard let authheader = Endpoint.getSessionKey(), let participantId = User.shared.userId else {
            return
        }
        OpenAPIClientAPI.basePath = LampURL.baseURLString
        OpenAPIClientAPI.customHeaders = ["Authorization": "Basic \(authheader)", "Content-Type": "application/json"]
      
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
}
