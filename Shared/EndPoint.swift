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
    
    /// Remove both bearer tokens from storage (session expired, or a non-bearer
    /// login replaced a bearer session). setToken(nil,...) only removes the
    /// authHeader, so the access token needs explicit removal here.
    static func clearBearerTokens() {
        UserDefaults.standard.removeObject(forKey: "BearerAccessToken")
        UserDefaults.standard.removeObject(forKey: "BearerRefreshToken")
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

    /// Same gate Networking uses for 401 refresh
    static var isBearerSession: Bool {
        return getBearerRefreshToken() != nil
    }

    /// Adds the one-time login query before the `#/…` hash, where the dashboard reads it
    static func dashboardURL(_ url: URL, finishLoginToken token: String) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let api = URLComponents(string: LampURL.baseURLString), let host = api.host else { return url }
        let serverAddress = host + (api.port.map { ":\($0)" } ?? "")
        components.queryItems = [
            URLQueryItem(name: "finishLoginToken", value: token),
            URLQueryItem(name: "serverAddress", value: serverAddress),
        ]
        return components.url ?? url
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
