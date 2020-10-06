//// mindLAMP
//
//import Foundation
//
//extension Date {
//    
//}
//
//class SensorLogs {
//    
//    static let shared = SensorLogs()
//    // MARK: - VARIABLES
//    
//    // MARK: - METHODS
//    private init() {}
//    
//    func createSensorLogsDirectory() {
//        FileStorage.createDirectory(name: Logs.Directory.sensorlogs, in: .documents)
//    }
//    
//    func storeSensorRequest(_ request: SensorData.Request) {
//        let timeStamp = Date().timeInMilliSeconds
//        let timeStampStr = Int(timeStamp).description
//        FileStorage.store(request, to: Logs.Directory.sensorlogs, in: .documents, as: timeStampStr + ".json")
//    }
//    
//    func fetchSensorRequest() -> [SensorData.Request] {
//        let urls = FileStorage.urls(for: Logs.Directory.logs, in: .documents)
//        var files = [String]()
//        urls?.forEach({ files.append($0.lastPathComponent) })
//        var requests = [SensorData.Request]()
//        for file in files {
//            if let request = FileStorage.retrieve(file, from: Logs.Directory.sensorlogs, in: .documents, as: SensorData.Request.self) {
//                requests.append(request)
//            }
//        }
//        return requests
//    }
//    
//    func clearLogsDirectory() {
//        FileStorage.clear(Logs.Directory.logs, in: .documents)
//    }
//}
