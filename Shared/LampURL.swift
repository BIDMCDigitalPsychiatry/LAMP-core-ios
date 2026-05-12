// mindLAMP
//https://thoughtbot.com/blog/let-s-setup-your-ios-environments

import Foundation

public enum MLEnvironment {
    
    // MARK: - Keys
    enum Keys {
      enum Plist {
        static let dashboardURL = "DASHBOARD_URL"
        static let branding = "Branding"
        static let OpenAPIClientAPI = "LAMP_API"
      }
    }
    
    static var isDiigApp: Bool {
        guard let appname = MLEnvironment.infoDictionary[Keys.Plist.branding] as? String else {
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
        guard let dasgboardURLstring = MLEnvironment.infoDictionary[Keys.Plist.dashboardURL] as? String else {
            fatalError("Root URL not set in plist for this environment")
        }
        return dasgboardURLstring
    }()
    
//    static let dashboardAPI: String = {
//        guard let endPoint = MLEnvironment.infoDictionary[Keys.Plist.dashboardAPI] as? String else {
//            fatalError("API Key not set in plist for this environment")
//        }
//        return endPoint
//    }()
    
    static let OpenAPIClientAPI: String = {
        guard let endPoint = MLEnvironment.infoDictionary[Keys.Plist.OpenAPIClientAPI] as? String else {
            fatalError("API Key not set in plist for this environment")
        }
        return endPoint
    }()
    
    static let appSource: String = {
        guard let source = MLEnvironment.infoDictionary[Keys.Plist.branding] as? String else {
            fatalError("API Key not set in plist for this environment")
        }
        return source
    }()
}

struct LampURL {
    // static let test = "http://127.0.0.1:5000/login"
    // static let dashboardlive = MLEnvironment.dashboardURL
    static var groupname = "group.digital.lamp.mindlamp"
    static var dashboardDigital: URL {
        return URL(string: dashboardDigitalURLText)!
    }
    static let dashboardDigitalURLText = MLEnvironment.dashboardURL //(UserDefaults.standard.launchURL ?? MLEnvironment.dashboardURL)// + "?a="
    //static let loginLocalHost = "http://127.0.0.1:5000/login"
    static let logsDigital = "https://logs.lamp.digital"
    //static let dashboardURL = MLEnvironment.dashboardAPI
    static let OpenAPIClientAPI = MLEnvironment.OpenAPIClientAPI

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
