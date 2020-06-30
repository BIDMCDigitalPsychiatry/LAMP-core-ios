//
//  NetworkingAPI.swift
//  mindLAMP Consortium
//
//  Created by ZCO Engineer on 07/04/16.
//

import Foundation

struct ContentTypeConstants {

    static let boundryString: String = "----WebKitFormBoundaryypF2fwBcAMX1vEFe"
    static let jSON: String = "application/json"
    static let uRLEncoded: String = "application/x-www-form-urlencoded"
    static var multiPart: String {
        return "multipart/form-data; boundary=\(boundryString)"
    }
}

struct MultiPartFields {
    struct FileData {
        var name: String//files[\(index)].fileContent
        var filename: String?
        var imageData: Data
        
        var key: String?//files[\(index)].fileName
        var value: String?//"abcd"
    }
    var fileContent: [FileData]
    init(fileContent: [FileData]) {
        self.fileContent = fileContent
    }
}

//typealias NetworkCompletion = (Result<JSONSerializable>) -> Void

protocol RequestProtocol {
    var jsonBody: [String: Any]? {get}
    func buildEndpoint() -> String
    func isAuth() -> Bool
    func getAPIKey() -> String?
    func getSessionToken() -> String?
    func getMultiPartDetails() -> MultiPartFields?
    func getRequestHeaders() -> [String: String]
    var requestTye: HTTPMethodType {get}
    var jsonData: Data? {get}
    //"pdf" or "png" etc.. If value exist for this property, then the task wil be download data task
    var downloadFileType: String? {get}
    var downloadFileName: String? {get}
}

enum HTTPMethodType {
    case post
    case get
    case put
    case delete
    
    func getTypeString() -> String {
        switch self {
            
        case .post:
            return "POST"
        case .get:
            return "GET"
        case .put:
            return "PUT"
        case .delete:
            return "DELETE"

        }
    }
}

enum HTTPContentType: String {
    case json
    case urlEncoded
    case multipart

    func toString() -> String {
        switch self {
        case .json:
            return ContentTypeConstants.jSON
        case .urlEncoded:
            return ContentTypeConstants.uRLEncoded
        case .multipart:
            return ContentTypeConstants.multiPart
        }
    }
}

protocol NetworkingAPI {

    /// make web service call using given http method and data
    ///
    /// - Parameters:
    ///   - method: get or post
    ///   - data: json body
    ///   - callback: 
    func makeWebserviceCall<T: Decodable>(with request: RequestProtocol, then callback: @escaping (Result<T>) -> Void)
    func cancelServiceCall()
}
