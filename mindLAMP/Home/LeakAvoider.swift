// mindLAMP

import Foundation
import WebKit
//https://stackoverflow.com/a/26383032/3913535
class LeakAvoider : NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        self.delegate?.userContentController(
            userContentController, didReceive: message)
    }
    
    static func cleanCache() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        print("[WebCacheCleaner] All cookies deleted")
        
//        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
//            records.forEach { record in
//                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
//                print("[WebCacheCleaner] Record \(record) deleted")
//            }
//        }
//        
//        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
//        let date = Date(timeIntervalSince1970: 0)
//        if let webData = websiteDataTypes as? Set<String> {
//            WKWebsiteDataStore.default().removeData(ofTypes: webData, modifiedSince: date, completionHandler:{ })
//        }
    }
}



