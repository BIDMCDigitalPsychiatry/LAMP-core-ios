////
////  NetworkingAPI.swift
////  mindLAMP Consortium
////
////  Created by ZCO Engineer on 07/04/16.
////
//
//import Foundation
//
//struct ContentTypeConstants {
//
//    static let jSON: String = "application/json"
//    static let uRLEncoded: String = "application/x-www-form-urlencoded"
//}
//
//
////typealias NetworkCompletion = (Result<JSONSerializable>) -> Void
//
//public protocol RequestProtocol {
//    var jsonBody: [String: Any]? {get}
//    func buildEndpoint() -> String
//    func isAuth() -> Bool
//    func getAPIKey() -> String?
//    func getSessionToken() -> String?
//    func getRequestHeaders() -> [String: String]
//    var requestTye: HTTPMethodType {get}
//    var jsonData: Data? {get}
//}
//
//public enum HTTPMethodType {
//    case post
//    case get
//    case put
//    case delete
//    
//    func getTypeString() -> String {
//        switch self {
//            
//        case .post:
//            return "POST"
//        case .get:
//            return "GET"
//        case .put:
//            return "PUT"
//        case .delete:
//            return "DELETE"
//
//        }
//    }
//}
//
//public enum HTTPContentType: String {
//    case json
//    case urlEncoded
//
//    public func toString() -> String {
//        switch self {
//        case .json:
//            return ContentTypeConstants.jSON
//        case .urlEncoded:
//            return ContentTypeConstants.uRLEncoded
//        }
//    }
//}
//
//public protocol NetworkingAPI {
//
//    /// make web service call using given http method and data
//    ///
//    /// - Parameters:
//    ///   - method: get or post
//    ///   - data: json body
//    ///   - callback:
//    func makeWebserviceCall<T: Decodable>(with request: RequestProtocol, then callback: @escaping (Result<T>) -> Void)
//    func cancelServiceCall()
//}
