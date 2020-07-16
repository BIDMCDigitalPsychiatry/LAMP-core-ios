// mindLAMP

import Foundation

extension Date {
    
    var timeInMilliSeconds: Double {
        return self.timeIntervalSince1970 * 1000
    }
}
