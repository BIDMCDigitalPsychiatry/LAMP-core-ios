//  mindLAMP Consortium

import Foundation

struct User {
    static let shared = User()
    private init(){}
    
    var userId: String? {
        return UserDefaults.standard.userID
    }
    
    func isLogin() -> Bool {
        return (Endpoint.getSessionKey() != nil) && (userId != nil)
    }
    
    func login(userID: String?, serverAddress: String?) {
        UserDefaults.standard.serverAddress = serverAddress
        UserDefaults.standard.userID = userID
    }
    
    func logout() {
        Endpoint.setSessionKey(nil)
        UserDefaults.standard.clearAll()
    }
    
    var loginInfo: [String: Any]? {
        if let sessionToken = Endpoint.getSessionKey(), let userId = userId {
            return [LoginInfoKey.sessionToken: sessionToken, LoginInfoKey.userId: userId]
        }
        return nil
    }
}
