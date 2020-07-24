// watchkitapp Extension

import Foundation

class ParticipantAPI {
    
    struct UserInfo: Decodable {
        let id: String
    }
    struct GetResponse: Decodable {
        
        let data: [UserInfo]
        /*
        {
        "data": [
        {
        "id": "xxxxxxx"
        }
        ]
        }
        */
        
    }
    
    var connection: NetworkingAPI
    init(_ connection: NetworkingAPI) {
        self.connection = connection
    }
    func getParticipant(userID: String, completion: @escaping (Bool, UserInfo?, Error?) -> Void) {
        
        let endPoint =  String(format: Endpoint.getParticipant.rawValue, userID)
        let data = RequestData(endpoint: endPoint, requestTye: HTTPMethodType.get)
        connection.makeWebserviceCall(with: data) { (response: Result<ParticipantAPI.GetResponse>) in
            switch response {
            case .failure(let err):
                completion(false, nil, err)
                //LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + err.errorMessage)
                break
            case .success(let responseData):
                let userInfo = responseData.data.first
                completion(true, userInfo, nil)
                break
            }
        }
    }
}

