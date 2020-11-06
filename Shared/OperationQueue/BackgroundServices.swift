//
//  BackgroundServices.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engg Dept on 14/01/20.

import Foundation
import UIKit
//import MONetworking

class BackgroundServices {
    //bgtasks
//    var backgroundTaskCounter: Int = 0
//    var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    
    static let shared = BackgroundServices()
    private var isInProgress = false
//    var completionHandler: ((UIBackgroundFetchResult) -> Void)?
    
//    func performTasksInBG(completionHandler: ((UIBackgroundFetchResult) -> Void)?) {
//        if nil == User.shared.userId { return }
//        self.completionHandler = completionHandler
//        self.performTasks()
//    }

    func performTasks() {

        DispatchQueue.global(qos: .background).async {
            if self.isInProgress == true {
                return
            }
            self.isInProgress = true
            let dispatchQueue = OperationQueue()
            dispatchQueue.maxConcurrentOperationCount = 1
            //+rollself.startBGTask(dispatchQueue)
            self.postSensorData(dispatchQueue)
            self.putLogsData(dispatchQueue)

            dispatchQueue.waitUntilAllOperationsAreFinished()
            
            self.isInProgress = false
            //+rollself.endBGTask(dispatchQueue)
        }
    }
    
    
}

//
//extension BackgroundServices {
//
//    func startBGTask(completion: () -> Void) {
//        if self.backgroundTaskCounter == 0 {
//            DispatchQueue.main.async { [weak self] in
//                self?.bgTask = UIApplication.shared.beginBackgroundTask(withName: "mindLAMP2") {
//                    guard let strongSelf = self else {return}
//                    if strongSelf.bgTask != UIBackgroundTaskIdentifier.invalid {
//                        UIApplication.shared.endBackgroundTask(strongSelf.bgTask)
//                        strongSelf.bgTask = UIBackgroundTaskIdentifier.invalid
//                    }
//                }
//            }
//            backgroundTaskCounter += 1
//            printDebug("Start BGTask...\(backgroundTaskCounter)")
//            completion()
//        } else {
//            backgroundTaskCounter += 1
//            printDebug("Start BGTask...\(backgroundTaskCounter)")
//            completion()
//        }
//
//    }
//    func endBGTask(completion: () -> Void) {
//        backgroundTaskCounter -= 1
//        if backgroundTaskCounter <= 0 {
//            DispatchQueue.main.async {
//                if self.bgTask != UIBackgroundTaskIdentifier.invalid {
//                    UIApplication.shared.endBackgroundTask(self.bgTask)
//                    self.bgTask = UIBackgroundTaskIdentifier.invalid
//                }
//            }
//            printDebug("End BGTask...\(backgroundTaskCounter)")
//            self.completionHandler?(.noData)
//            completion()
//        } else {
//            self.completionHandler?(.noData)
//            completion()
//        }
//
//    }
//    func endBGTask(_ dispatchQueue: OperationQueue) {
//        let operation = BGTaskOperation(opType: .stop)
//        dispatchQueue.addOperation(operation)
//    }
//    func startBGTask(_ dispatchQueue: OperationQueue) {
//        let operation = BGTaskOperation(opType: .start)
//        dispatchQueue.addOperation(operation)
//    }
//}

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
        //ToDo: add configuration to make it dynamically . only work for production
        let arrLogsData = LMLogsManager.shared.fetchLogsRequest()
        let endPoint =  Endpoint.logs.rawValue
        for logsData in arrLogsData {
            let request = RequestData(endpoint: endPoint, requestTye: .put, urlParams: logsData.urlParams, data: logsData.dataBody)
            let operation = BackgroundOperation(request: request, connection: NetworkConfig.logsNetworkingAPI(), opType: .logs)
            dispatchQueue.addOperation(operation)
        }
         
    }
}
