// mindLAMP

import Foundation

class NotificationWebViewModel: NSObject, ObservableObject {
    
    @Published var shouldAnimate = true
    var pageURL: URL?
    var pageTitle: String?

    init(_ url: URL?, pageTitle: String?) {
        self.pageURL = url
        self.pageTitle = pageTitle
    }
}
