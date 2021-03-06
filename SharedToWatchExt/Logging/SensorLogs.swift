// mindLAMP

import Foundation
import LAMP

extension Date {
    
}

class SensorLogs {
    
    static let shared = SensorLogs()
    static let sensorSpecfileName = "SensorSpecs.json"
    // MARK: - VARIABLES
    
    // MARK: - METHODS
    private init() {}
    
    func createSensorLogsDirectory() {
        FileStorage.createDirectory(name: Logs.Directory.sensorlogs, in: .documents)
    }
    
    func storeSensorSpecs(specs: [Sensor]) {
        FileStorage.store(specs, to: Logs.Directory.sensorSpecs, in: .documents, as: SensorLogs.sensorSpecfileName)
    }
    
    func fetchSensorSpecs() -> [Sensor]? {
        let data = FileStorage.retrieve(SensorLogs.sensorSpecfileName, from: Logs.Directory.sensorSpecs, in: .documents, as: [Sensor].self)
        return data
    }
    // pass filename if you want to keep only one
    func storeSensorRequest(_ request: SensorData.Request, fileNameWithoutExt: String? = nil) {
        let fileName: String
        if let fName = fileNameWithoutExt {
            fileName = fName
        } else {
            let timeStamp = Date().timeInMilliSeconds
            fileName = UInt64(timeStamp).description
        }
        FileStorage.store(request, to: Logs.Directory.sensorlogs, in: .documents, as: fileName + ".json")
    }

    func fetchSensorRequest() -> [(String, SensorData.Request)] {
        let urls = FileStorage.urls(for: Logs.Directory.sensorlogs, in: .documents)
        var files = [String]()
        urls?.forEach({ files.append($0.lastPathComponent) })
        var requests = [(String, SensorData.Request)]()
        for file in files {
            if let request = FileStorage.retrieve(file, from: Logs.Directory.sensorlogs, in: .documents, as: SensorData.Request.self) {
                requests.append((file, request))
            }
        }
        return requests
    }
    
    func printAllFiles() {
        let urls = FileStorage.urls(for: Logs.Directory.sensorlogs, in: .documents)
        var files = [String]()
        urls?.forEach({ files.append($0.lastPathComponent) })
        for file in files {
            print("\nfile = \(file)")
        }
    }
    
    func deleteFile(_ fileName: String) {
        FileStorage.remove(fileName, from: Logs.Directory.sensorlogs, in: .documents)
    }
    
    func clearLogsDirectory() {
        FileStorage.clear(Logs.Directory.sensorlogs, in: .documents)
        FileStorage.clear(Logs.Directory.sensorSpecs, in: .documents)
    }
}
