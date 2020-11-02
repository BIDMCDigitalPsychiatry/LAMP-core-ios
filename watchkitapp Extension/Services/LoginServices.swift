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
                //LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + err.errorMessage)
                break
            case .success(let responseData):
                let userInfo = responseData.data.first
                completion(true, userInfo, nil)
                break
            }
        }
    }
//    
//    func login(userID: String, request: PushNotification.UpdateTokenRequest,  completion: @escaping (Bool) -> Void) {
//
//        let endPoint = String(format: Endpoint.participantServerEvent.rawValue, userID)
//        let data = RequestData(endpoint: endPoint, requestTye: HTTPMethodType.post, data: request)
//        connection.makeWebserviceCall(with: data) { (response: Result<PushNotification.UpdateTokenResponse>) in
//            switch response {
//            case .failure:
//                completion(false)
//                //UserDefaults.standard.logData = "sendDeviceToken done"
//                //LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + err.errorMessage)
//                break
//            case .success(_):
//                //UserDefaults.standard.logData = "sendDeviceToken failue"
//                completion(true)
//                break
//            }
//        }
//    }
}

