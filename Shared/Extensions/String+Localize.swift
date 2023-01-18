// mindLAMP
import Foundation

extension String {
    var localized: String {
//        let path = Bundle.main.path (forResource: "fr", ofType: "lproj")
//        let languageBundle = Bundle (path: path!)
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main , value: "", comment: "")
    }
}
