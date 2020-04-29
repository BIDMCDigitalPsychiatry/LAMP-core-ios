import UIKit
import Foundation

enum ServerError {
    case webServiceResponseIsNil
    case jsonParsingFailed
    case invalidJSONDataStructure
    case keyMissing(String)
    case noReachability
    case sessionExpired
    case subscribtionExpired
    func errorMessage() -> String {
        switch self {
        case .webServiceResponseIsNil:
            return "error.server.unknown".localized
        case .jsonParsingFailed:
            return "error.server.unknown".localized//"JSON parsing failed."
        case .invalidJSONDataStructure:
            return "error.server.unknown".localized//"JSON Data structure is invalid"
        case .keyMissing(let key):
            return "Required key \(key) missing"//"error.server.unknown".localized()//
        case .noReachability:
            return "alert.no.connectivity".localized
        case .sessionExpired:
            return "alert.session.expired".localized
        case .subscribtionExpired:
            return "error.user.unknown".localized
        }
    }
}

enum ErrorKind {
    case definedError(ServerError)
    case customError(Int)// > 0 represents a validation error from server. 0 or negative value is a validation error from app
    case networkError(Int)
    case otherError
}
struct LMError: Error {
    private var kind: ErrorKind
    var isValidationErrorFromServer: Bool {
        switch kind {
            
        case .definedError, .networkError, .otherError:
            return false
        case .customError(let errorCode):
            return errorCode > 0
        }
    }
    
    var isOtherError: Bool {
        switch kind {
            
        case .definedError, .networkError, .customError:
            return false
        case .otherError:
            return true
        }
    }
    
    var isAlertTobeHidden: Bool {
        switch kind {
            
        case .definedError, .customError:
            return false
        case .otherError:
            return false
        case .networkError(let errorCode):
            if errorCode == -999 {
                return true
            } else {
                return false
            }
        }
    }
    
    var isLoggedOut: Bool {
        switch kind {
            
        case .definedError(let serverErr):
            switch serverErr {
            case .sessionExpired:
                return true
            default:
                return false
            }
        case .customError:
            return false
        case .networkError(let errorCode):
            if errorCode == 401 || errorCode == 403 { 
                return true
            } else {
                return false
            }
        case .otherError:
            return false
        }
    }
    var message: String
    init(_ errorKind: ErrorKind, msg: String = "") {
        message = msg
        kind = errorKind
    }
    static func errorFromErr(_ err: Error) -> LMError {
        return LMError(ErrorKind.otherError, msg: err.localizedDescription)
    }
    
    func networkMessage(errorCode: Int) -> String {
        
        let message: String
        switch errorCode {
        case 300...399:
            message = "error.server.unknown".localized//"Unexpected redirect from server."
        case 401:
            message = "error.user.unknown".localized//"Unauthorized."
        case 403:
            message = "error.user.unknown".localized//"Unauthorized."
        case 400...499:
            message = "error.server.unknown".localized//"Bad request."
        case 500...599:
            message = "error.server.unknown".localized//"Server error."
        case -999:
            message = "error.server.cancelled".localized//"user cancelled error."
        default:
            message = "error.server.unknown".localized//"Unexpected status code \(errorCode)."
        }
        return message
    }
}

extension LMError {
    public var errorMessage: String {
        switch kind {
        case .otherError:
            return message
        case .customError:
            return message
        case .definedError(let error):
            return error.errorMessage()
        case .networkError(let code):
            return networkMessage(errorCode: code)
        }
    }
    
}

