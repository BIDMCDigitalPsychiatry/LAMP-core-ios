// watchkitapp Extension

import Foundation

class NotificationAPI {
    
    var connection: NetworkingAPI
    init(_ connection: NetworkingAPI) {
        self.connection = connection
    }
    func sendDeviceToken(request: WatchNotification.UpdateTokenRequest,  completion: @escaping (Bool) -> Void) {
        
        guard let userID = User.shared.userId else {
            completion(false)
            return
        }
        let endPoint =  String(format: Endpoint.participantServerEvent.rawValue, userID)
        let data = RequestData(endpoint: endPoint, requestTye: HTTPMethodType.post, data: request)
        connection.makeWebserviceCall(with: data) { (response: Result<WatchNotification.UpdateTokenResponse>) in
            switch response {
            case .failure:
                completion(false)
                //LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + err.errorMessage)
                break
            case .success(_):
                completion(true)
                break
            }
        }
    }
}
