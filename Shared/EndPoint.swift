// mindLAMP

import Foundation

enum Endpoint: String {
    
    case logs = "/"
    case participantSensorEvent = "/participant/%@/sensor_event"
    case getParticipant = "/participant/me"
    
    case getLatestDashboard = "/version/get"
    
    static func setSessionKey(_ token: String?) {
        UserDefaults.standard.set(token, forKey: "authToken")
    }
    static func getSessionKey() -> String? {
        return UserDefaults.standard.object(forKey: "authToken") as? String
    }
    
    static func setURLToken(_ token: String?) {
        UserDefaults.standard.set(token, forKey: "URLToken")
    }
    static func getURLToken() -> String? {
        return UserDefaults.standard.object(forKey: "URLToken") as? String
    }
    
    static func getAPIKey() -> String? {
        return nil
    }
    
    static func appendURLTokenTo(urlString: String) -> String {
        var populatedURLString = urlString
        if urlString.hasPrefix("http") == false {
            var baseurl = LampURL.dashboardDigitalURLText
            if urlString.hasPrefix("/") && baseurl.hasSuffix("/") {
                baseurl = String(baseurl.dropLast())
            }
            populatedURLString = baseurl + urlString
        }
//        if let token = getURLToken() {
//            return "\(populatedURLString)?a=\(token)"
//        }
        return populatedURLString
    }
}
