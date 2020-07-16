// mindLAMP

import Foundation

class SensorEvents {
    
    func postSensorData() {
        
        let request = LMWatchSensorManager.shared.getLatestDataRequest()
        guard let userID = User.shared.userId else { return }
        let endPoint =  String(format: Endpoint.participantServerEvent.rawValue, userID)
        let requestData = RequestData(endpoint: endPoint, requestTye: .post, data: request)

        let connection = NetworkConfig.networkingAPI()
        connection.makeWebserviceCall(with: requestData) { (response: Result<SensorData.Response>) in
            switch response {
            case .failure(let err):
                //LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + err.localizedMessage)
                break
            case .success(_):
                print("success watch update")
                break
            }
        }
    }
}
