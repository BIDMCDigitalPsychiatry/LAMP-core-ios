// mindLAMP

#if os(iOS)
import Foundation
import UIKit

extension UIDevice {
    // Available Idioms - .pad, .phone, .tv, .carPlay, .unspecified
    static let isRunningOnIpad = UIDevice.current.userInterfaceIdiom == .pad ? true : false
    static let isRunningOnIphone = UIDevice.current.userInterfaceIdiom == .phone ? true : false
}
#endif
