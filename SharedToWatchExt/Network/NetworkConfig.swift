//
//  NetworkConfig.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engg Dept on 25/08/16.
//

import Foundation
//import MONetworking

class NetworkConfig {

    class var logsURL: String {
        return LampURL.logsDigital
    }

    static func logsNetworkingAPI() -> NetworkingAPI {
        return Networking(baseURL: URL(string: NetworkConfig.logsURL)!, isBackgroundSession: false)
    }
    
    static func networkingAPI(isBackgroundSession: Bool = false) -> NetworkingAPI {
        return Networking(baseURL: URL(string: LampURL.baseURLString)!, isBackgroundSession: isBackgroundSession)
    }
   
}

struct RequestData: RequestProtocol {
    var jsonBody: [String : Any]?
    var jsonData: Data?
    var endpoint: String//Endpoint
    var parameters: [String: Any]?
    var endpointDetails: String
    var contentType: HTTPContentType = .json
    var requestTye: HTTPMethodType
    var headers: [String: String]?
    
    func getRequestHeaders() -> [String: String] {
        
        var requestHeaders: [String: String] = [String: String]()
        switch contentType {
        case .json:
            requestHeaders["Content-Type"] = contentType.toString()
        case .urlEncoded:
            requestHeaders["Content-Type"] = contentType.toString()
        }
        
        if isDashboard() {
            if let headerDict = headers {
                for (key, value) in headerDict {
                    requestHeaders[key] = value
                }
            }
        }
        else if isAuth() {
            if let token = getSessionToken() {
                requestHeaders["Authorization"] = "Basic \(token)"
            }
            if let apikey = getAPIKey() {
                requestHeaders["API-KEY"] = apikey
            }
        }
        return requestHeaders
    }
    
    //only for posting json
    init(endpoint: String, requestType: HTTPMethodType, endpointDetails: String = "", urlParams: Encodable? = nil, body: [String: Any]? = nil) {
        self.requestTye = requestType
        self.endpoint = endpoint
        self.endpointDetails = endpointDetails
        if let params = urlParams {
            self.parameters = (params as? DictionaryEncodable)?.dictionary()
        }
        
        self.jsonBody = body //?? [String: Any]()
        
        if parameters != nil {
            self.contentType = .urlEncoded
        }
        if jsonBody != nil {
            self.contentType = .json
        }

    }
    
    
    init<T: Encodable>(endpoint: String, requestTye: HTTPMethodType, urlParams: Encodable? = nil, data: T?, endpointDetails: String = "") {
        self.requestTye = requestTye
        self.endpoint = endpoint
        self.endpointDetails = endpointDetails
        if requestTye == .get {
            self.parameters = (data as? DictionaryEncodable)?.dictionary()
        }
        if let params = urlParams {
            self.parameters = (params as? DictionaryEncodable)?.dictionary()
        }
        if requestTye == .post || requestTye == .put {
            let encoder = JSONEncoder()
            //let formatter = Date.jsonDateEncodeFormatter
            //encoder.dateEncodingStrategy = .formatted(formatter)//.millisecondsSince1970
            do {
                if let obj = data {
                    jsonData = try encoder.encode(obj)
                }
            } catch let error {
                print("encode errr = \(error)")
            }
        }
        if parameters != nil {
            self.contentType = .urlEncoded
        }
        if let postData = jsonData, postData.count > 0 {
            self.contentType = .json
        }
    }
    
    init(endpoint: String, requestTye: HTTPMethodType, urlParams: Encodable? = nil, jsonData: Data?, endpointDetails: String = "") {
        self.requestTye = requestTye
        self.endpoint = endpoint
        self.endpointDetails = endpointDetails
        if requestTye == .get {
            self.parameters = (jsonData as? DictionaryEncodable)?.dictionary()
        }
        if let params = urlParams {
            self.parameters = (params as? DictionaryEncodable)?.dictionary()
        }
        if requestTye == .post || requestTye == .put {
            self.jsonData = jsonData
        }
        if parameters != nil {
            self.contentType = .urlEncoded
        }
        if let postData = jsonData, postData.count > 0 {
            self.contentType = .json
        }
    }
    
    init(endpoint: String, requestTye: HTTPMethodType, urlParams: Encodable? = nil, headers: [String: String]? = nil) {
        self.requestTye = requestTye
        self.endpoint = endpoint
        self.endpointDetails = ""
        self.headers = headers
        
        if let params = urlParams {
            self.parameters = (params as? DictionaryEncodable)?.dictionary()
        }
        if parameters != nil {
            self.contentType = .urlEncoded
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
        print("queryString = \(queryString)")
        return queryString
    }
    
    func buildEndpoint() -> String {
        return "\(endpoint)\(buildParameters())\(endpointDetails)"
    }
    func isAuth() -> Bool {
        guard let endURL = Endpoint(rawValue: endpoint) else {
            if endpoint.hasPrefix("/participant/") {return true}
            return false }
        
        switch endURL {
        case .logs, .getLatestDashboard:
            return false
        case .participantSensorEvent, .getParticipant, .sensor, .activity, .activityEvent:
            return true
        }
    }
    func isDashboard() -> Bool {
        guard let endURL = Endpoint(rawValue: endpoint) else { return false }
        
        switch endURL {
        case .getLatestDashboard:
            return true
        case .logs, .participantSensorEvent, .getParticipant, .sensor, .activity, .activityEvent:
            return false
        }
    }
    func getAPIKey() -> String? {
        return Endpoint.getAPIKey()
    }
    func getSessionToken() -> String? {
        return Endpoint.getSessionKey()
    }

}

