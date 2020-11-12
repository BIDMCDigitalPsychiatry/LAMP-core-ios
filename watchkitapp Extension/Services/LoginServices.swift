// watchkitapp Extension

import Foundation
//import MONetworking

class LoginAPI {

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
        
        let endPoint =  Endpoint.getParticipant.rawValue
        let data = RequestData(endpoint: endPoint, requestTye: HTTPMethodType.get)
        connection.makeWebserviceCall(with: data) { (response: Result<LoginAPI.GetResponse>) in
            switch response {
            case .failure(let err):
                completion(false, nil, err)
                if let nsError = err as NSError? {
                    let errorCode = nsError.code
                    /// -1009 is the offline error code
                    /// so log errors other than connection issue
                    if errorCode != -1009 {
                        LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + err.localizedMessage)
                    }
                }
                break
            case .success(let responseData):
                let userInfo = responseData.data.first
                completion(true, userInfo, nil)
                break
            }
        }
    }
}

