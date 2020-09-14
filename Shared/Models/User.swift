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
        print("Endpoint.getSessionKey() = \(Endpoint.getSessionKey())")
        print("userId = \(userId)")
        return (Endpoint.getSessionKey() != nil) && (userId != nil)
    }
    
    func login(userID: String?, serverAddress: String?) {
        print("userId = \(userID)")
        print("serverAddress = \(serverAddress)")
        UserDefaults.standard.serverAddress = serverAddress
        UserDefaults.standard.userID = userID
    }
    
    func logout() {
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
