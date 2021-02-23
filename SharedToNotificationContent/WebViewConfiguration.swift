// mindLAMP

import Foundation
import WebKit

struct WebConfiguration {
    
    static func getWebViewConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        if let id = UserDefaults.standard.userIDShared, let password = UserDefaults.standard.passwordShared {
            var values: [AnyHashable : Any] =  ["id":id, "password":password]
            if let serverAdd = UserDefaults.standard.serverAddressShared {
                values["serverAddress"] = serverAdd
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: values, options: [])
                if let value = String(data: data, encoding: .utf8) {
                    let contentController = WKUserContentController()
                    let js = "javascript: sessionStorage.setItem('LAMP._auth', '\(value)')"
                    let userScript = WKUserScript(source: js, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
                    contentController.addUserScript(userScript)
                    configuration.userContentController = contentController
                }
            } catch let error {
                print("web error = \(error.localizedDescription)")
            }
            
        }
        return configuration
    }
}
