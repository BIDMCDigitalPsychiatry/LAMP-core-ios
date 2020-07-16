// watchkitapp Extension

import WatchKit
import Foundation
import SwiftUI

class HostingController: WKHostingController<ContentView> {
    
    override var body: ContentView {
        let isLogged = UserDefaults.standard.bool(forKey: "islogged") == true
        return ContentView(userAuth: UserAuth(isLogged))
    }

}
