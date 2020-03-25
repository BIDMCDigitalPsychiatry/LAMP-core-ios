//
//  BackgroundOperation.swift
//  lampv2
//
//  Created by ZCo Engg Dept on 14/01/20.
//

import Foundation

enum OperationType {
    case sensorData
    case logs
}

enum BgTaskOperation {
    case start
    case stop
}
class BGTaskOperation: AsyncOperation {
    var opType: BgTaskOperation
    override func main() {
        super.main()
        if !self.isCancelled {
            switch opType {
            case .start:
                state = .executing
                BackgroundServices.shared.startBGTask {
                    state = .finished
                }
            case .stop:
                state = .executing
                BackgroundServices.shared.endBGTask {
                    state = .finished
                    
                    // Clear logs.
                    LMLogsManager.shared.clearLogsDirectory()
                }
            }
        }
    }
    init(opType: BgTaskOperation) {
        self.opType = opType
    }
}

class BackgroundOperation: AsyncOperation {

    var request: RequestData
    let connection: NetworkingAPI
    let opType: OperationType
    
    init(request: RequestData, connection: NetworkingAPI = NetworkConfig.networkingAPI(), opType: OperationType = .sensorData) {
        self.request = request
        self.connection = connection
        self.opType = opType
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
                LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + err.errorMessage)
                break
            case .success(_):
                
                break
            }
        }
    }
    
    func putLogs() {
        connection.makeWebserviceCall(with: request) { (response: Result<LogsData.Response>) in
            self.state = .finished
            switch response {
            case .failure(let err):
                LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + err.errorMessage)
                break
            case .success(_):
                break
            }
        }
    }
}
