//
//  BackgroundOperation.swift
//  lampv2
//
//  Created by ZCo Engg Dept on 14/01/20.
//

import Foundation

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
    let connection = NetworkConfig.networkingAPI()
    
    init(request: RequestData) {
        self.request = request
    }
    override func main() {
        super.main()
        if !self.isCancelled {
            postSensorData()
        }
    }
}
private extension BackgroundOperation {

    func postSensorData() {
        
        connection.makeWebserviceCall(with: request) { (response: Result<SensorData.Response>) in
            self.state = .finished
        }
    }
    
}
