// mindLAMP

import Foundation

struct User {
    static let shared = User()
    private init(){}
    
    var userId: String? {
        return UserDefaults.standard.userID
    }
    
    func isLogin() -> Bool {
        return (Endpoint.getSessionKey() != nil) && (UserDefaults.standard.userID != nil)
    }
    
    func login(userID: String?, serverAddress: String?) {
        UserDefaults.standard.serverAddress = serverAddress
        UserDefaults.standard.userID = userID
    }
    
    func logout() {
        Endpoint.setSessionKey(nil)
        UserDefaults.standard.clearAll()
    }
}
