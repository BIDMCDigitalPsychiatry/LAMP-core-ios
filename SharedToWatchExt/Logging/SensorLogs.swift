// mindLAMP

import Foundation
import LAMP

struct FileInfo: Encodable {
    var name: String
    var size: String
}

struct FileName: Encodable {
    var nameWithoutExt: String
    var name: String
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

//    func fetchSensorRequest() -> [(String, SensorData.Request)] {
//        let urls = FileStorage.urls(for: Logs.Directory.sensorlogs, in: .documents)
//        var files = [String]()
//        urls?.forEach({ files.append($0.lastPathComponent) })
//        var requests = [(String, SensorData.Request)]()
//        for file in files {
//            if let request = FileStorage.retrieve(file, from: Logs.Directory.sensorlogs, in: .documents, as: SensorData.Request.self) {
//                requests.append((file, request))
//            }
//        }
//        return requests
//    }
    
//    func fetchSensorRequest(count: Int = 10) -> [(String, SensorData.Request)] {
//        let urls = FileStorage.urls(for: Logs.Directory.sensorlogs, in: .documents)
//        guard let fileObjects = urls?.map({ FileName(nameWithoutExt: $0.deletingPathExtension().lastPathComponent, name: $0.lastPathComponent) }) else { return [] }
//        
//        let fileObjecsSorted = fileObjects.sorted(by: { (item1, item2) -> Bool in
//            if let d1 = Double(item1.nameWithoutExt), let d2 = Double(item2.nameWithoutExt) {
//                return d1 < d2
//            } else {
//                return false
//            }
//        })
//        
//        let files = Array(fileObjecsSorted.prefix(count)).map { (f) -> String in
//            f.name
//        }
//        var requests = [(String, SensorData.Request)]()
//        for file in files {
//            if let request = FileStorage.retrieve(file, from: Logs.Directory.sensorlogs, in: .documents, as: SensorData.Request.self) {
//                requests.append((file, request))
//            }
//        }
//        return requests
//    }
    
    func fetchSensorRequest(count: Int = 10) -> [(String, Data)] {
        let urls = FileStorage.urls(for: Logs.Directory.sensorlogs, in: .documents)
        guard let fileObjects = urls?.map({ FileName(nameWithoutExt: $0.deletingPathExtension().lastPathComponent, name: $0.lastPathComponent) }) else { return [] }
        
        let fileObjecsSorted = fileObjects.sorted(by: { (item1, item2) -> Bool in
            if let d1 = Double(item1.nameWithoutExt), let d2 = Double(item2.nameWithoutExt) {
                return d1 < d2
            } else {
                return false
            }
        })
        
        let files = Array(fileObjecsSorted.prefix(count)).map { (f) -> String in
            f.name
        }
        var requests = [(String, Data)]()
        for file in files {
            if let request = FileStorage.retrieve(file, from: Logs.Directory.sensorlogs, in: .documents) {
                requests.append((file, request))
            }
        }
        
        return requests
    }
    
    func getAllPendingFiles() -> [FileInfo]? {
        let urls = FileStorage.urls(for: Logs.Directory.sensorlogs, in: .documents)
       
        let files = urls?.map({ FileInfo(name: $0.deletingPathExtension().lastPathComponent, size: $0.fileSizeString) })
        return files?.sorted(by: { (item1, item2) -> Bool in
            if let d1 = Double(item1.name), let d2 = Double(item2.name) {
                return d1 < d2
            } else {
                return false
            }
        })
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

extension URL {
    var attributes: [FileAttributeKey : Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            print("FileAttribute error: \(error)")
        }
        return nil
    }

    var fileSize: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
    }

    var fileSizeString: String {
        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }

    var creationDate: Date? {
        return attributes?[.creationDate] as? Date
    }
}
