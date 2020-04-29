//
//  LogsModel.swift
//  mindLAMP
//
//  Created by Zco Engineer on 18/03/20.
//

import Foundation

enum LogsLevel: String {
    case info
    case warning
    case error
    case fatal
}

extension LogsLevel: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct LogsData {
    
    struct Request: Codable {
        let dataBody: Body
        let urlParams: Params
    }
    
    struct Response: Codable {
    }
}

extension LogsData {
    
    struct Body: Codable {
        let userId: String?
        let userAgent: UserAgent
        let message: String?
    }

    struct Params: DictionaryEncodable & Decodable {
        let origin: String
        let level: LogsLevel
    }
}

extension LogsData.Body {
    
    struct UserAgent: Codable {
        let name: String?
        let osVersion: String?
        let model: String?
    }
}
