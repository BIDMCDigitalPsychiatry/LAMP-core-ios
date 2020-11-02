//
//  BackgroundOperation.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engg Dept on 14/01/20.
//

import Foundation
//import MONetworking

enum OperationType {
    case sensorData
    case logs
}

//enum BgTaskOperation {
//    case start
//    case stop
//}
//class BGTaskOperation: AsyncOperation {
//    var opType: BgTaskOperation
//    override func main() {
//        super.main()
//        if !self.isCancelled {
//            switch opType {
//            case .start:
//                state = .executing
//                BackgroundServices.shared.startBGTask {
//                    state = .finished
//                }
//            case .stop:
//                state = .executing
//                BackgroundServices.shared.endBGTask {
//                    state = .finished
//
//                    // Clear logs.
//                    LMLogsManager.shared.clearLogsDirectory()
//                }
//            }
//        }
//    }
//    init(opType: BgTaskOperation) {
//        self.opType = opType
//    }
//}

class BackgroundOperation: AsyncOperation {

    var request: RequestData
    let connection: NetworkingAPI
    let opType: OperationType
    let fileName: String?
    
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
                //+rollLMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + err.localizedMessage)
                break
            case .success(_):
                //TODO: remove file from disk
                if let file = self.fileName {
                    SensorLogs.shared.deleteFile(file)
                    printToFile("\n deleted file\(file)")
                    print("\n deleted file\(file)")
                }
                break
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
                //TODO: remove file from disk
                break
            }
        }
    }
}
