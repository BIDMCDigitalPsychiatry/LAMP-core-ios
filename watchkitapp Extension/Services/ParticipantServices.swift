// watchkitapp Extension

import Foundation

class ParticipantAPI {
    
    var connection: NetworkingAPI
    init(_ connection: NetworkingAPI) {
        self.connection = connection
    }
    func getParticipant(userID: String, completion: @escaping (Bool, Error?) -> Void) {
        
        let endPoint =  String(format: Endpoint.getParticipant.rawValue, userID)
        let data = RequestData(endpoint: endPoint, requestTye: HTTPMethodType.get)
        connection.makeWebserviceCall(with: data) { (response: Result<WatchNotification.UpdateTokenResponse>) in
            switch response {
            case .failure(let err):
                completion(false, err)
                //LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + err.errorMessage)
                break
            case .success(_):
                completion(true, nil)
                break
            }
        }
    }
}

