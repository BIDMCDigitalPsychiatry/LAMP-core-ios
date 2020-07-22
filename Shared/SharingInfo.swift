// mindLAMP

import Foundation

//send from iOS to Watch
struct IOSCommands {
    static let login = "login"
    static let sendWatchSensorEvents = "sendWatchSensorEvents"
    static let logout = "logout"
}

struct LoginInfoKey {
    static let sessionToken = "sessionToken"
    static let userId = "userId"
}

struct LoginInfo {
    let sessionToken: String
    let userId: String
    
    init(_ dict: [String: Any]) {
        guard let token = dict[LoginInfoKey.sessionToken] as? String,
            let id = dict[LoginInfoKey.userId] as? String else {
                fatalError("Timed color dictionary doesn't have right keys!")
        }
        self.sessionToken = token
        self.userId = id
    }
}

