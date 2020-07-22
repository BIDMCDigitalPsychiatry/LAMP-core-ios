// mindLAMP

import Foundation

class SensorEvents {

    func postSensorData() {
        
        let request = LMWatchSensorManager.shared.getLatestDataRequest()
        guard let userID = User.shared.userId, User.shared.isLogin() == true else {
            return }
        let endPoint =  String(format: Endpoint.participantServerEvent.rawValue, userID)
        let requestData = RequestData(endpoint: endPoint, requestTye: .post, data: request)

        let connection = NetworkConfig.networkingAPI()
        connection.makeWebserviceCall(with: requestData) { (response: Result<SensorData.Response>) in
            
            
            Utils.postNotificationOnMainQueueAsync(name: .sensorDataPosted)
            switch response {
            case .failure:
                //UserDefaults.standard.logData = "postSensorData failue"
                //LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + err.localizedMessage)
                break
            case .success(_):
                //UserDefaults.standard.logData = "postSensorData done"
                break
            }
        }
    }
}
