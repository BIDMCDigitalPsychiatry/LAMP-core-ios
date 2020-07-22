// watchkitapp Extension

import WatchKit
import Foundation
import SwiftUI

class HostingController: WKHostingController<ContentView> {

    override var body: ContentView {
        let isLogged = User.shared.isLogin()
        return ContentView(userAuth: UserAuth(isLogged))
    }

}
