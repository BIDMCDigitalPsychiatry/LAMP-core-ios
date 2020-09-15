// mindLAMP

import Foundation

struct LampURL {
    //static let test = "http://127.0.0.1:5000/login"
    static let dashboardlive = "https://dashboard.lamp.digital/#/"//"https://dashboard-staging.lamp.digital" ////TODO:
    static var dashboardDigital: URL {
        return URL(string: UserDefaults.standard.launchURL ?? dashboardlive)!
    }
    static let dashboardDigitalWithToken = (UserDefaults.standard.launchURL ?? dashboardlive) // + "/#/"//"/#/?a="
    //static let loginLocalHost = "http://127.0.0.1:5000/login"
    static let logsDigital = "https://logs.lamp.digital"
    static let dashboardURL = "http://52.66.237.209:9092"
    static let lampAPI = "https://api.lamp.digital"
    
}
