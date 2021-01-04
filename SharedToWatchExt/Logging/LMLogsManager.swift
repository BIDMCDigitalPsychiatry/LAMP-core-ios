//
//  LMLogsManager.swift
//  mindLAMP Consortium
//
//  Created by Zco Engineer on 17/03/20.
//

import Foundation
import UIKit
import LAMP

class LMLogsManager {
    
    static let shared = LMLogsManager()
    // MARK: - VARIABLES
    
    // MARK: - METHODS
    private init() {}
    
    func createLogsDirectory() {
        FileStorage.createDirectory(name: Logs.Directory.logs, in: .documents)
    }
    
    func addLogs(level: LogsLevel, logs: String) {
        let userAgent = UserAgent.defaultAgent.toString()
        let body = LogsData.Body(userId: User.shared.userId, userAgent: userAgent, message: logs)
        let params = LogsData.Params(origin: Logs.URLParams.origin, level: level)
        let request = LogsData.Request(dataBody: body, urlParams: params)
        
        let timeStamp = Date().timeInMilliSeconds
        let timeStampStr = UInt64(timeStamp).description
        FileStorage.store(request, to: Logs.Directory.logs, in: .documents, as: timeStampStr + ".json")
    }
    
    func fetchLogsRequest() -> [(String, LogsData.Request)] {
        let urls = FileStorage.urls(for: Logs.Directory.logs, in: .documents)
        var files = [String]()
        urls?.forEach({ files.append($0.lastPathComponent) })
        var requests = [(String, LogsData.Request)]()
        for file in files {
            if let request = FileStorage.retrieve(file, from: Logs.Directory.logs, in: .documents, as: LogsData.Request.self) {
                requests.append((file, request))
            }
        }
        return requests
    }
    
    func deleteFile(_ fileName: String) {
        FileStorage.remove(fileName, from: Logs.Directory.logs, in: .documents)
    }
    
    func clearLogsDirectory() {
        FileStorage.clear(Logs.Directory.logs, in: .documents)
    }
}
