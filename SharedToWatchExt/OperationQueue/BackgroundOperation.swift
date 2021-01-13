//
//  BackgroundOperation.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engg Dept on 14/01/20.
//

import Foundation
import LAMP
import Combine

enum OperationType {
    case sensorData
    case logs
}

class BackgroundOperation: AsyncOperation {

    let opType: OperationType
    let fileName: String?
    var sensorRequest: SensorData.Request?
    var logRequest: LogsData.Request?
    var subscriberSensor: AnyCancellable?
    var subscriberLogs: AnyCancellable?
    
    init(sensorRequest: SensorData.Request, opType: OperationType = .sensorData, fileName: String? = nil) {
        self.opType = opType
        self.fileName = fileName
        self.sensorRequest = sensorRequest
    }
    init(logRequest: LogsData.Request, opType: OperationType = .logs, fileName: String? = nil) {
        self.opType = opType
        self.fileName = fileName
        self.logRequest = logRequest
    }
    override func main() {
        super.main()
        if !self.isCancelled {
            switch opType {

            case .sensorData:
                postSensorData()
            case .logs:
                putLogs()
            }
            
        }
    }
}
private extension BackgroundOperation {

    func postSensorData() {

        guard let authheader = Endpoint.getSessionKey(), let participantId = User.shared.userId, let sensorRequestUnwrapped = sensorRequest else {
            printError("Auth header missing")
            return
        }
        OpenAPIClientAPI.basePath = LampURL.baseURLString
        OpenAPIClientAPI.customHeaders = ["Authorization": "Basic \(authheader)", "Content-Type": "application/json"]
        let publisher = SensorEventAPI.sensorEventCreate(participantId: participantId, sensorEvent: sensorRequestUnwrapped, apiResponseQueue: DispatchQueue.global())
        subscriberSensor = publisher.sink { value in
            self.state = .finished
            switch value {
            case .failure(let ErrorResponse.error(code, data, error)):
                printError("postSensorData error code\(code), \(error.localizedDescription)")
                var msg: String?
                if let data = data {
                    printError("Error Json: \(String(describing: String(data: data, encoding: String.Encoding.utf8)))")
                    let decoder = JSONDecoder()
                    do {
                        let errResponse = try decoder.decode(ErrResponse.self, from: data)
                        msg = errResponse.error
                    } catch let err {
                        printError("err = \(err.localizedDescription)")
                    }
                }
                let errorMsg = msg ?? error.localizedDescription
                LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + errorMsg)
                
            case .failure(let error):
                printError("postSensorData error \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    let errorCode = nsError.code
                    /// -1009 is the offline error code
                    /// so log errors other than connection issue
                    if errorCode == -1009 {
                        LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.network_error + " " + nsError.localizedDescription)
                    } else {
                        LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + nsError.localizedDescription)
                    }
                }
            case .finished:
                if let file = self.fileName {
                    SensorLogs.shared.deleteFile(file)
                    printToFile("\n deleted data file \(file)")
                }
            }
        } receiveValue: { (stringValue) in
            print("postSensorData receiveValue = \(stringValue)")
        }
    }
    
    func putLogs() {
        
        guard let authheader = Endpoint.getSessionKey(), let participantId = User.shared.userId, let logRequest = logRequest else {
            return
        }
        print("put logs now")
        OpenAPIClientAPI.customHeaders = ["Authorization": "Basic \(authheader)", "Content-Type": "application/json"]
        let publisher = LogsAPI.logsCreate(participantId: participantId, logsData: logRequest)
        subscriberLogs = publisher.sink { value in
            self.state = .finished
            switch value {
            case .failure(let ErrorResponse.error(code, data, error)):
                printError("putLogs error code\(code), \(error.localizedDescription)")
                if let data = data {
                    printError("Error Json: \(String(describing: String(data: data, encoding: String.Encoding.utf8)))")
                }
            case .failure(let error):
                printError("putLogs error \(error.localizedDescription)")
            case .finished:
                if let file = self.fileName {
                    LMLogsManager.shared.deleteFile(file)
                    printToFile("\n deleted data file \(file)")
                }
            }
        } receiveValue: { (stringValue) in
            print("putLogs receiveValue = \(stringValue)")
        }
    }
}
