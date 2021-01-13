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
            dispatchQueue.maxConcurrentOperationCount = 2
            self.postSensorData(dispatchQueue)
            self.putLogsData(dispatchQueue)

            dispatchQueue.waitUntilAllOperationsAreFinished()
            
            self.isInProgress = false
        }
    }
}

extension BackgroundServices {
    
    func postSensorData(_ dispatchQueue: OperationQueue) {
        
        let arrSensorData = SensorLogs.shared.fetchSensorRequest()
        printToFile("arrSensorData count = \(arrSensorData.count)")
        for fileAndRequest in arrSensorData {
            let operation = BackgroundOperation(sensorRequest: fileAndRequest.1, fileName: fileAndRequest.0)
            dispatchQueue.addOperation(operation)
        }
    }
    
    func putLogsData(_ dispatchQueue: OperationQueue) {
        let arrLogsData = LMLogsManager.shared.fetchLogsRequest()
        for logRequest in arrLogsData {
            let operation = BackgroundOperation(logRequest: logRequest.1, fileName: logRequest.0)
            dispatchQueue.addOperation(operation)
        }
    }
}
