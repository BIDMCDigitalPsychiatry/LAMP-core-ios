// mindLAMP
//https://thoughtbot.com/blog/let-s-setup-your-ios-environments

import Foundation

public enum Environment {
    
    // MARK: - Keys
    enum Keys {
      enum Plist {
        static let dashboardURL = "DASHBOARD_URL"
        static let branding = "Branding"
        static let OpenAPIClientAPI = "LAMP_API"
      }
    }
    
    static var isDiigApp: Bool {
        guard let appname = Environment.infoDictionary[Keys.Plist.branding] as? String else {
            return false
        }
        return appname == "DiiG"
    }
    
    // MARK: - Plist
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        return dict
    }()
    
    // MARK: - Plist values
    static let dashboardURL: String = {
        guard let dasgboardURLstring = Environment.infoDictionary[Keys.Plist.dashboardURL] as? String else {
            fatalError("Root URL not set in plist for this environment")
        }
        return dasgboardURLstring
    }()
    
//    static let dashboardAPI: String = {
//        guard let endPoint = Environment.infoDictionary[Keys.Plist.dashboardAPI] as? String else {
//            fatalError("API Key not set in plist for this environment")
//        }
//        return endPoint
//    }()
    
    static let OpenAPIClientAPI: String = {
        guard let endPoint = Environment.infoDictionary[Keys.Plist.OpenAPIClientAPI] as? String else {
            fatalError("API Key not set in plist for this environment")
        }
        return endPoint
    }()
    
    static let appSource: String = {
        guard let source = Environment.infoDictionary[Keys.Plist.branding] as? String else {
            fatalError("API Key not set in plist for this environment")
        }
        return source
    }()
}

struct LampURL {
    // static let test = "http://127.0.0.1:5000/login"
    // static let dashboardlive = Environment.dashboardURL
    static var groupname = "group.digital.lamp.mindlamp"
    static var dashboardDigital: URL {
        return URL(string: dashboardDigitalURLText)!
    }
    static let dashboardDigitalURLText = Environment.dashboardURL //(UserDefaults.standard.launchURL ?? Environment.dashboardURL)// + "?a="
    //static let loginLocalHost = "http://127.0.0.1:5000/login"
    static let logsDigital = "https://logs.lamp.digital"
    //static let dashboardURL = Environment.dashboardAPI
    static let OpenAPIClientAPI = Environment.OpenAPIClientAPI

    /// Multipart video upload control plane (`globalThis.VIDEO_UPLOAD_SERVICE_CONFIG` on web).
    static let videoUploadServiceBaseURLString = "https://video.dev.lamp.digital"
    /// Full `Authorization` header (`Bearer …`) for the video upload API.
    static let videoUploadServiceAuthorizationHeader =
        "Basic emNvLW1pY2hhZWw6YjU3NDJmNzgtM2ZlYy0xMWYxLWFiNzItZGZmZDA4Mzc1MTY3"
    
    static var baseURLString: String {
        if let url = UserDefaults.standard.serverAddress {
            return url
        } else {
            return LampURL.OpenAPIClientAPI
        }
    }
    
}
