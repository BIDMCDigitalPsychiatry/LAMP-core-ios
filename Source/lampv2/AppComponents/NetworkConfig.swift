//
//  NetworkConfig.swift
//  lampV2
//
//  Created by ZCo Engg Dept on 25/08/16.
//  Copyright © 2016 lamp. All rights reserved.
//

import Foundation

enum Endpoint: String {
    
    case login = ""
    case postApi = "/postapi"
    case status = "/status"
    case participantServerEvent = "/participant/%@/sensor_event"
    
    static func setSessionKey(_ token: String?) {
        UserDefaults.standard.set(token, forKey: "authToken")
        UserDefaults.standard.synchronize()
    }
    static func getSessionKey() -> String? {
        return UserDefaults.standard.object(forKey: "authToken") as? String
    }
   
    static func getAPIKey() -> String? {
        return nil
    }
}

class NetworkConfig {
    static let kErrorSessionExpired = 1002
    static let kErrorInvalidSessionKey = 1003
    static let kErrorSubscriptionExpied = 1004
    static let kErrorUnknown = 2037
    
    class func baseURL() -> String {
        
        if let url = UserDefaults.standard.serverAddress {
            return url
        } else {
            return "https://api.lamp.digital"
        }
    }
    
    static func networkingAPI() -> NetworkingAPI {
        return Networking(baseURL: URL(string: NetworkConfig.baseURL())!, session: URLSession(configuration: URLSessionConfiguration.default))
    }
    
    static func isSessionExpired(_ errorCode: Int) -> ServerError? {
        if errorCode == NetworkConfig.kErrorSessionExpired || errorCode == NetworkConfig.kErrorInvalidSessionKey {
            return ServerError.sessionExpired
        } else if errorCode == NetworkConfig.kErrorSubscriptionExpied {
            return ServerError.subscribtionExpired
        } else {
            return nil
        }
    }
}

struct RequestData: RequestProtocol {
    var jsonData: Data?
    var endpoint: String//Endpoint
    var parameters: [String: Any]?
    var endpointDetails: String
    var multiPartDetails: MultiPartFields?
    var contentType: HTTPContentType = .json
    var requestTye: HTTPMethodType
    
    //"pdf" or "png" etc.. If value exist for this property, then the task wil be download data task
    var downloadFileType: String?
    var downloadFileName: String?
    
    func getRequestHeaders() -> [String: String] {
        
        var requestHeaders: [String: String] = [String: String]()
        switch contentType {
        case .json:
            requestHeaders["Content-Type"] = contentType.toString()
        case .urlEncoded, .multipart:
            requestHeaders["Content-Type"] = contentType.toString()
        }
        
        if let token = getSessionToken() {
            //requestHeaders["Authorization"] = "Bearer \(token)"
            //requestHeaders["sessionToken"] = token
            requestHeaders["Authorization"] = "Basic \(token)"
        } else {
            if !isAuth() {
                // Fail
            }
        }
        if let apikey = getAPIKey() {
            printDebug("API-KEY: \(apikey)")
            requestHeaders["API-KEY"] = apikey
        }
        
        return requestHeaders
    }
    
    init<T: Encodable>(endpoint: String, requestTye: HTTPMethodType, data: T?, endpointDetails: String = "", multiPartDetails: MultiPartFields? = nil, downloadFileType: String? = nil, downloadFileName: String? = nil) {
        self.requestTye = requestTye
        self.endpoint = endpoint
        self.endpointDetails = endpointDetails
        self.downloadFileType = downloadFileType
        self.downloadFileName = downloadFileName
        if requestTye == .get {
            self.parameters = (data as? DictionaryEncodable)?.dictionary()
        }
        if requestTye == .post {
            let encoder = JSONEncoder()
            let formatter = Date.jsonDateEncodeFormatter
            encoder.dateEncodingStrategy = .formatted(formatter)//.millisecondsSince1970
            do {
                if let obj = data {
                    jsonData = try encoder.encode(obj)
                }
            } catch let error {
                printError("encode errr = \(error)")
            }
        }
        self.multiPartDetails = multiPartDetails
        if multiPartDetails != nil {
            self.contentType = .multipart
        } else {
            if parameters != nil {
                self.contentType = .urlEncoded
            }
            if let postData = jsonData, postData.count > 0 {
                self.contentType = .json
            }
        }
        
    }
    func buildParameters() -> String {
        var queryString = ""
        if let intKeys = parameters?["params"] as? [Int] {
            for key in intKeys {
                queryString += "/"
                queryString += "\(key)"
            }
            return queryString
        }
        guard let dictParams = parameters else {
            return queryString
        }
        let keys = Array(dictParams.keys)
        for (name, value) in dictParams {
            if keys.first == name {
                queryString = "?"
            }
            if let strvalue = value as? String {
                if let escapedString = strvalue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    queryString += "\(name)=\(escapedString)"
                }
            } else {
                queryString += "\(name)=\(value)"
            }
            if keys.last != name {
                queryString += "&"
            }
        }
        printDebug("queryString = \(queryString)")
        return queryString
    }
    
    func buildEndpoint() -> String {
        return "\(endpoint)\(buildParameters())\(endpointDetails)"
    }
    func isAuth() -> Bool {
        if Endpoint.login.rawValue == endpoint {
            return true
        }
        return false
    }
    func getAPIKey() -> String? {
        return Endpoint.getAPIKey()
    }
    func getSessionToken() -> String? {
        return Endpoint.getSessionKey()
    }
    
    func getMultiPartDetails() -> MultiPartFields? {
        return multiPartDetails
    }
}

