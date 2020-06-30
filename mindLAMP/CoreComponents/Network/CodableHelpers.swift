//
//  CodableHelpers.swift
//  mindLAMP Consortium
//
//  Created by ZCO Engineer on 22/10/18.

import Foundation

protocol DictionaryEncodable: Encodable {}

extension DictionaryEncodable {
    func dictionary() -> [String: Any]? {
        let encoder = JSONEncoder()
        let formatter = Date.jsonDateEncodeFormatter
        encoder.dateEncodingStrategy = .formatted(formatter)//.millisecondsSince1970
        guard let json = try? encoder.encode(self),
            let dict = ((try? JSONSerialization.jsonObject(with: json, options: []) as? [String: Any]) as [String: Any]??) else {
                return nil
        }
        return dict
    }
}

extension KeyedDecodingContainer {
    public func decode<T: Decodable>(_ key: Key, as type: T.Type = T.self) throws -> T {
        return try self.decode(T.self, forKey: key)
    }
    
    public func decodeIfPresent<T: Decodable>(_ key: KeyedDecodingContainer.Key) throws -> T? {
        return try decodeIfPresent(T.self, forKey: key)
    }
}
//
//struct ErrorResponse {
//    let errorCode: Int?
//    let message: String?
//    init(errorCode: Int?, message: String?) {
//        self.errorCode = errorCode
//        self.message = message
//    }
//}
struct Safe<Base: Decodable>: Decodable {
    enum MyStructKeys: String, CodingKey { // declaring our keys
        case errorCode
        case errorMessage
        //case data
    }
    
    let value: Base
    var errorCode: Int?
    var message: String?
    init(from decoder: Decoder) throws {
        do {
            
            let container = try decoder.container(keyedBy: MyStructKeys.self) // defining our (keyed) container
            
            if let errorCode = try container.decodeIfPresent(Int.self, forKey: .errorCode), errorCode > 0 {
                if let sessionError = NetworkConfig.isSessionExpired(errorCode) {
                    Endpoint.setSessionKey(nil)
                    throw LMError(.definedError(sessionError))
                } else if let errMsg = try container.decodeIfPresent(String.self, forKey: .errorMessage) {
                    throw LMError(.customError(errorCode), msg: errMsg)
                } else {
                    throw LMError(.customError(errorCode), msg: "Unexpected error code \(errorCode).")
                }
            }
            
            //value = try container.decode(.data)
            let container2 = try decoder.singleValueContainer()
            value = try container2.decode(Base.self)
        } catch let error {
            
            if let handledErr = error as? LMError {
                throw handledErr
            } else {
                let msg = (error as NSError).userInfo[NSDebugDescriptionErrorKey]
                printDebug("err msg = \(String(describing: msg))")
                throw LMError(.customError(0), msg: error.localizedDescription)
            }
        }
    }
}
