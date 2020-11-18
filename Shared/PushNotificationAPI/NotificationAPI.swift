//  mindLAMP Consortium

import Foundation
//import MONetworking

class NotificationAPI {
    
    var connection: NetworkingAPI
    init(_ connection: NetworkingAPI) {
        self.connection = connection
    }
    
    func sendDeviceToken(request: PushNotification.UpdateTokenRequest,  completion: @escaping (Bool) -> Void) {
        
        guard let userID = User.shared.userId else {
            print("return ..no useid")
            completion(false)
            return
        }
        let endPoint =  String(format: Endpoint.participantSensorEvent.rawValue, userID)
        let data = RequestData(endpoint: endPoint, requestTye: HTTPMethodType.post, data: request)
        connection.makeWebserviceCall(with: data) { (response: Result<PushNotification.UpdateTokenResponse>) in
            switch response {
            case .failure( _):
                completion(false)
                break
            case .success(_):
                completion(true)
                break
            }
        }
    }
    
    func sendPushAcknowledgement(request: PushNotification.UpdateReadRequest, completion: @escaping () -> Void) {
        
        guard let userID = User.shared.userId else {
            return
        }
        let endPoint = String(format: Endpoint.participantSensorEvent.rawValue, userID)
        let data = RequestData(endpoint: endPoint, requestType: HTTPMethodType.post, body: request.toJSON())
        connection.makeWebserviceCall(with: data) { (response: Result<PushNotification.UpdateReadResponse>) in
            switch response {
            case .failure( _):
                completion()
            case .success(_):
                completion()
            }
        }
    }
}
