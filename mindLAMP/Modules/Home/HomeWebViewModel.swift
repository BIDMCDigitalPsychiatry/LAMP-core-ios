//  mindLAMP Consortium

import Foundation
import WebKit

enum ScriptMessageHandler: String {
    case login = "login"
    case logout = "logout"
}

enum ScriptMessageKey: String {
    case authorizationToken = "authorizationToken"
    case identityObject = "identityObject"
    case serverAddress = "serverAddress"
}

class WebViewStorage {
    static let shared = WebViewStorage()
    let processPool = WKProcessPool()
    let dataStore = WKWebsiteDataStore.default()
}
//
//extension WKWebViewConfiguration {
//    /// Async Factory method to acquire WKWebViewConfigurations packaged with system cookies
//    static func cookiesIncluded(completion: @escaping (WKWebViewConfiguration?) -> Void) {
//        let config = WKWebViewConfiguration()
//        guard let cookies = HTTPCookieStorage.shared.cookies else {
//            completion(config)
//            return
//        }
//        // Use nonPersistent() or default() depending on if you want cookies persisted to disk
//        // and shared between WKWebViews of the same app (default), or not persisted and not shared
//        // across WKWebViews in the same app.
//        let dataStore = WKWebsiteDataStore.default()
//        let waitGroup = DispatchGroup()
//        for cookie in cookies {
//            waitGroup.enter()
//            dataStore.httpCookieStore.setCookie(cookie) { waitGroup.leave() }
//        }
//        waitGroup.notify(queue: DispatchQueue.main) {
//            config.websiteDataStore = dataStore
//            completion(config)
//        }
//    }
//}
