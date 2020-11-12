//
//  BackgroundServices.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engg Dept on 14/01/20.

import Foundation
import UIKit

class BackgroundServices {
    
    static let shared = BackgroundServices()
    private var isInProgress = false

    func performTasks() {

        DispatchQueue.global(qos: .background).async {
            if self.isInProgress == true {
                return
            }
            self.isInProgress = true
            let dispatchQueue = OperationQueue()
            dispatchQueue.maxConcurrentOperationCount = 1
            self.postSensorData(dispatchQueue)
            self.putLogsData(dispatchQueue)

            dispatchQueue.waitUntilAllOperationsAreFinished()
            
            self.isInProgress = false
        }
    }
}

extension BackgroundServices {
    
    func postSensorData(_ dispatchQueue: OperationQueue) {
        guard let userID = User.shared.userId else { return }
        let arrSensorData = SensorLogs.shared.fetchSensorRequest()
        let endPoint =  String(format: Endpoint.participantSensorEvent.rawValue, userID)
        for fileAndRequest in arrSensorData {
            let requestData = RequestData(endpoint: endPoint, requestTye: .post, data: fileAndRequest.1)
            let operation = BackgroundOperation(request: requestData, fileName: fileAndRequest.0)
            dispatchQueue.addOperation(operation)
        }
    }
    
    func putLogsData(_ dispatchQueue: OperationQueue) {
        let arrLogsData = LMLogsManager.shared.fetchLogsRequest()
        let endPoint =  Endpoint.logs.rawValue
        for logsData in arrLogsData {
            let request = RequestData(endpoint: endPoint, requestTye: .put, urlParams: logsData.urlParams, data: logsData.dataBody)
            let operation = BackgroundOperation(request: request, connection: NetworkConfig.logsNetworkingAPI(), opType: .logs)
            dispatchQueue.addOperation(operation)
        }
         
    }
}
