//  mindLAMP Consortium

import Foundation

enum ScriptMessageHandler: String {
    case login = "login"
    case logout = "logout"
}

enum ScriptMessageKey: String {
    case authorizationToken = "authorizationToken"
    case identityObject = "identityObject"
    case serverAddress = "serverAddress"
}
