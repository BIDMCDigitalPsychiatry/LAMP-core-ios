// mindLAMP

import Foundation

class SensorEvents {
    static var lastUpdated: Date?
    func postSensorData() {
        
        if let lastUpdatedTime = SensorEvents.lastUpdated, Date().distance(to: lastUpdatedTime) < 60 {
            //UserDefaults.standard.logData = "distance = \(Date().distance(to: lastUpdatedTime))"
            return
        }
        if let lastUpdatedTime = SensorEvents.lastUpdated {
            //UserDefaults.standard.logData = "distance2 = \(Date().distance(to: lastUpdatedTime))"
        }
        SensorEvents.lastUpdated = Date()
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
