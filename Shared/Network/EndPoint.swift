// mindLAMP

import Foundation

enum Endpoint: String {
    
    case logs = "/"
    case participantServerEvent = "/participant/%@/sensor_event"
    case getParticipant = "/participant/%@"
    
    static func setSessionKey(_ token: String?) {
        UserDefaults.standard.set(token, forKey: "authToken")
        UserDefaults.standard.synchronize()
    }
    static func getSessionKey() -> String? {
        return UserDefaults.standard.object(forKey: "authToken") as? String
    }
    
    static func getAPIKey() -> String? {
        return nil
    }
}
