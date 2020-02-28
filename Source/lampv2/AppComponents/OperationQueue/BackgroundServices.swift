//
//  BackgroundServices.swift
//  lampv2
//
//  Created by ZCo Engg Dept on 14/01/20.
//  Copyright © 2020 lamp. All rights reserved.

import Foundation
import UIKit

class BackgroundServices {
    //bgtasks
    var backgroundTaskCounter: Int = 0
    var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    
    static let shared: BackgroundServices = BackgroundServices()
    private var isInProgress = false
    var completionHandler: ((UIBackgroundFetchResult) -> Void)?
    
    func performTasksInBG(completionHandler: ((UIBackgroundFetchResult) -> Void)?) {
        if nil == UserDefaults.standard.userID { return }
        self.completionHandler = completionHandler
        self.performTasks()
    }

    func performTasks() {

        DispatchQueue.global(qos: .background).async {
            if self.isInProgress == true {
                printError("progressing ...")
                return
            }
            self.isInProgress = true
            let dispatchQueue = OperationQueue()
            self.startBGTask(dispatchQueue)
            self.postSensorData(dispatchQueue)

            dispatchQueue.waitUntilAllOperationsAreFinished()
            
            self.isInProgress = false
            self.endBGTask(dispatchQueue)
        }
    }
    
    
}


extension BackgroundServices {

    func startBGTask(completion: () -> Void) {
        if self.backgroundTaskCounter == 0 {
            DispatchQueue.main.async { [weak self] in
                self?.bgTask = UIApplication.shared.beginBackgroundTask(withName: "mindLAMP2") {
                    guard let strongSelf = self else {return}
                    if strongSelf.bgTask != UIBackgroundTaskIdentifier.invalid {
                        UIApplication.shared.endBackgroundTask(strongSelf.bgTask)
                        strongSelf.bgTask = UIBackgroundTaskIdentifier.invalid
                    }
                }
            }
            backgroundTaskCounter += 1
            printDebug("Start BGTask...\(backgroundTaskCounter)")
            completion()
        } else {
            backgroundTaskCounter += 1
            printDebug("Start BGTask...\(backgroundTaskCounter)")
            completion()
        }
        
    }
    func endBGTask(completion: () -> Void) {
        backgroundTaskCounter -= 1
        if backgroundTaskCounter <= 0 {
            DispatchQueue.main.async {
                if self.bgTask != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(self.bgTask)
                    self.bgTask = UIBackgroundTaskIdentifier.invalid
                }
            }
            printDebug("End BGTask...\(backgroundTaskCounter)")
            self.completionHandler?(.noData)
            completion()
        } else {
            self.completionHandler?(.noData)
            completion()
        }
        
    }
    func endBGTask(_ dispatchQueue: OperationQueue) {
        let operation = BGTaskOperation(opType: .stop)
        dispatchQueue.addOperation(operation)
    }
    func startBGTask(_ dispatchQueue: OperationQueue) {
        let operation = BGTaskOperation(opType: .start)
        dispatchQueue.addOperation(operation)
    }
    
    func postSensorData(_ dispatchQueue: OperationQueue) {
        
        let requests = SensorManager.shared.fetchSensorDataRequest()
        guard let userID = UserDefaults.standard.userID else { return }
        let endPoint =  String(format: Endpoint.participantServerEvent.rawValue, userID)
        for requestData in requests {
            let request = RequestData(endpoint: endPoint, requestTye: .post, data: requestData)
            let operation = BackgroundOperation(request: request)
            dispatchQueue.addOperation(operation)
        }
        
    }
}
