// mindLAMP

import Foundation

enum NetworkError: Error {
    case invalidURL
    case noResponse
    case errorResponse(String)
    
    public var localizedText: String {
        switch self {

        case .invalidURL:
            return NSLocalizedString("error.invalid.url", comment: "Invalid URL")
        case .noResponse:
            return NSLocalizedString("error.server.notresponding", comment: "Server is not responding!")
        case .errorResponse(let msg):
            return msg
        }
    }
}


extension Error {

    public var localizedMessage: String {
        if let err = self as? NetworkError {
            return err.localizedText
        } else {
            return self.localizedDescription
        }
    }
}
