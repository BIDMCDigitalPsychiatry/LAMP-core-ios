// mindLAMP
//https://thoughtbot.com/blog/let-s-setup-your-ios-environments

import Foundation

public enum Environment {
    
    // MARK: - Keys
    enum Keys {
      enum Plist {
        static let dashboardURL = "DASHBOARD_URL"
        static let dashboardAPI = "DASHBOARD_API"
        static let lampAPI = "LAMP_API"
      }
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
    
    static let dashboardAPI: String = {
        guard let endPoint = Environment.infoDictionary[Keys.Plist.dashboardAPI] as? String else {
            fatalError("API Key not set in plist for this environment")
        }
        return endPoint
    }()
    
    static let lampAPI: String = {
        guard let endPoint = Environment.infoDictionary[Keys.Plist.lampAPI] as? String else {
            fatalError("API Key not set in plist for this environment")
        }
        return endPoint
    }()
}

struct LampURL {
    //static let test = "http://127.0.0.1:5000/login"
    //static let dashboardlive = Environment.dashboardURL
    static var dashboardDigital: URL {
        return URL(string: dashboardDigitalURLText)!
    }
    static let dashboardDigitalURLText = (UserDefaults.standard.launchURL ?? Environment.dashboardURL)// + "?a="
    //static let loginLocalHost = "http://127.0.0.1:5000/login"
    static let logsDigital = "https://logs.lamp.digital"
    static let dashboardURL = Environment.dashboardAPI
    static let lampAPI = Environment.lampAPI
    
}
