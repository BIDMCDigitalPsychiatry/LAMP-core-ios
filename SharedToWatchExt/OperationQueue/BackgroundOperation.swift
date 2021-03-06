//
//  BackgroundOperation.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engg Dept on 14/01/20.
//

import Foundation
import LAMP
//import Combine

enum OperationType {
    case sensorData
    case logs
}

class BackgroundOperation: AsyncOperation {

    var request: RequestData
    let connection: NetworkingAPI
    let opType: OperationType
    let fileName: String?
    //var sensorRequest: SensorData.Request?
    //var logRequest: LogsData.Request?
    //var subscriberSensor: AnyCancellable?
    //var subscriberLogs: AnyCancellable?
    
    init(request: RequestData, connection: NetworkingAPI = NetworkConfig.networkingAPI(), opType: OperationType = .sensorData, fileName: String? = nil) {
        self.request = request
        self.connection = connection
        self.opType = opType
        self.fileName = fileName
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
        connection.makeWebserviceCall(with: request) { (response: Result<SensorData.Response>) in
            self.state = .finished
            switch response {
            case .failure(let err):
                if let nsError = err as NSError? {
                    let errorCode = nsError.code
                    /// -1009 is the offline error code
                    /// so log errors other than connection issue
                    if errorCode != -1009 {
                        LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + err.localizedMessage)
                    }
                }
            case .success(_):
                //remove file from disk
                if let file = self.fileName {
                    SensorLogs.shared.deleteFile(file)
                    printToFile("\n deleted data file \(file)")
                }
            }
        }
    }
    
    func putLogs() {
        connection.makeWebserviceCall(with: request) { (response: Result<LogsData.Response>) in
            self.state = .finished
            switch response {
            case .failure:
                break
            case .success:
                //remove file from disk
                if let file = self.fileName {
                    LMLogsManager.shared.deleteFile(file)
                    printToFile("\n deleted log file \(file)")
                }
            }
        }
    }
}
