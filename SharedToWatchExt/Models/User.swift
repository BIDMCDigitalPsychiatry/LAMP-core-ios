//  mindLAMP Consortium

import Foundation

struct User {
    static let shared = User()
    private init(){}
    
    var userId: String? {
        return UserDefaults.standard.userID
    }
    
    var serverURL: String? {
        return UserDefaults.standard.serverAddress
    }

    func isLogin() -> Bool {
        print("Endpoint.getSessionKey() = \(String(describing: Endpoint.getSessionKey()))")
        print("userId = \(String(describing: userId))")
        return (Endpoint.getSessionKey() != nil) && (userId != nil)
    }
    
    #if os(iOS)
    func login(userID: String?, username: String?, password: String?, serverAddress: String?) {
        print("userId = \(String(describing: userID))")

        let serverAddressWithHttps = serverAddress?.makeURLString()
        print("serverAddress = \(String(describing: serverAddress))")
        UserDefaults.standard.passwordShared = password
        UserDefaults.standard.serverAddress = serverAddressWithHttps
        UserDefaults.standard.serverAddressShared = serverAddressWithHttps?.cleanHostName()
        UserDefaults.standard.userIDShared = username
        UserDefaults.standard.userID = userID
        UserDefaults.standard.setInitalSensorRecorderTimestamp()
    }
    #endif
    
    #if os(watchOS)
    func login(userID: String?, serverAddress: String?) {

        let serverAddressWithHttps = serverAddress?.makeURLString()
       
        UserDefaults.standard.serverAddress = serverAddressWithHttps
        UserDefaults.standard.userID = userID
        UserDefaults.standard.setInitalSensorRecorderTimestamp()
    }
    #endif
    
    func logout() {
        //Stop all sensors
        LMSensorManager.shared.stopSensors(islogout: true)
        
        SensorLogs.shared.clearLogsDirectory()
        LMLogsManager.shared.clearLogsDirectory()
        
        Endpoint.setSessionKey(nil)
        UserDefaults.standard.clearAll()
    }
    
    var loginInfo: [String: Any]? {
        if let sessionToken = Endpoint.getSessionKey(), let userId = userId, let address = serverURL {
            return [LoginInfoKey.sessionToken: sessionToken, LoginInfoKey.userId: userId, LoginInfoKey.serverAddress: address]
        }
        return nil
    }
}
