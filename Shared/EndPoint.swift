// mindLAMP

import Foundation

enum Endpoint: String {
    
    enum AuthType {
        case basic
        case bearer
    }
    
    case logs = "/"
    case participantSensorEvent = "/participant/%@/sensor_event"
    case sensor = "/participant/%@/sensor"
    case getParticipant = "/participant/me"
    case activity = "/participant/%@/activity?ignore_binary=true"
    case activityEvent = "/participant/%@/activity_event"//?ignore_binary=true
    
    case getLatestDashboard = "/version/get"
    
    static func setToken(_ token: String?, for authType: AuthType) {
        guard let token = token else {
            UserDefaults.standard.removeObject(forKey: "authHeader")
            return
        }
        switch authType {
        case .basic:
            let header = "Basic \(token)"
            UserDefaults.standard.set(header, forKey: "authHeader")
        case .bearer:
            setBearerAccessToken(token)
            let header = "Bearer \(token)"
            UserDefaults.standard.set(header, forKey: "authHeader")
        }
    }
    
    private static func setBearerAccessToken(_ token: String?) {
        UserDefaults.standard.set(token, forKey: "BearerAccessToken")
    }
    static func setBearerRefreshToken(_ token: String?) {
        UserDefaults.standard.set(token, forKey: "BearerRefreshToken")
    }
    
    static func getBearerAccessToken() -> String? {
        UserDefaults.standard.string(forKey: "BearerAccessToken")
    }
    static func getBearerRefreshToken() -> String? {
        UserDefaults.standard.string(forKey: "BearerRefreshToken")
    }
    
    static func setBase64BasicAuth(_ authToken: String?) {
        UserDefaults.standard.set(authToken, forKey: "authToken")
    }
    static func getBase64BasicAuth() -> String? {
        return UserDefaults.standard.object(forKey: "authToken") as? String
    }
    
    static func setAuthHeader(_ authHeader: String?) {
        UserDefaults.standard.set(authHeader, forKey: "authHeader")
    }
    static func getAuthHeader() -> String? {
        return UserDefaults.standard.object(forKey: "authHeader") as? String
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
