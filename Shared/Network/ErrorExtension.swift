// mindLAMP

import Foundation

enum NetworkError: Error {
    case invalidURL
    case noResponse
    case errorResponse(String)
    
    var localizedText: String {
        switch self {

        case .invalidURL:
            return "Invalid URL"
        case .noResponse:
            return "Server is not responding!"
        case .errorResponse(let msg):
            return msg
        }
    }
}


extension Error {
    var localizedMessage: String {
        if let err = self as? NetworkError {
            return err.localizedText
        } else {
            return self.localizedDescription
        }
    }
}
