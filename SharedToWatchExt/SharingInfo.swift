// mindLAMP

import Foundation

//send from iOS to Watch
struct IOSCommands {
    static let login = "login"
    static let sendWatchSensorEvents = "sendWatchSensorEvents"
    static let logout = "logout"
    
    static let timestamp = "timestamp"
}

struct LoginInfoKey {
    static let sessionToken = "sessionToken"
    static let userId = "userId"
    static let serverAddress = "serverAddress"
    static let password = "password"
}

struct LoginInfo {
    let sessionToken: String
    let userId: String
    let serverAddress: String
    
    init(_ dict: [String: Any]) {
        guard let token = dict[LoginInfoKey.sessionToken] as? String,
            let address = dict[LoginInfoKey.serverAddress] as? String,
            let id = dict[LoginInfoKey.userId] as? String else {
                fatalError("Timed color dictionary doesn't have right keys!")
        }
        self.sessionToken = token
        self.userId = id
        self.serverAddress = address
    }
}

