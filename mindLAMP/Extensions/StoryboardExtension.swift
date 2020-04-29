// mindLAMP

import Foundation
import UIKit

extension UIStoryboard {
    
    class var home: UIStoryboard {
        return UIStoryboard(name: "Home", bundle: Bundle.main)
    }
}

/**
 A protocol specific to the Lister sample that represents the segue identifier
 constraints in the app. Every view controller provides a segue identifier
 enum mapping. This protocol defines that structure.
 
 We also want to provide implementation to each view controller that conforms
 to this protocol that helps box / unbox the segue identifier strings to
 segue identifier enums. This is provided in an extension of `SegueHandlerType`.
 */
public protocol StoryboardIdentifiable {

    static func storyboard() -> UIStoryboard
    static func instantiateViewControllerFromStoryboard(_ storyBoard: UIStoryboard, storyboardID: String) -> UIViewController
}
extension StoryboardIdentifiable where Self: UIViewController {

    public static func getController() -> Self {
        guard let viewController =  Self.instantiateViewControllerFromStoryboard(storyboard(), storyboardID: String(describing: Self.self)) as? Self else {
            fatalError("getController cast issue")
        }
        return viewController
    }

    public static func instantiateViewControllerFromStoryboard(_ storyBoard: UIStoryboard, storyboardID: String) -> UIViewController {
        return storyBoard.instantiateViewController(withIdentifier: storyboardID)
    }
    
    public static func storyboard() -> UIStoryboard {
        return UIStoryboard.home
    }
}
extension UIViewController: StoryboardIdentifiable {
}
