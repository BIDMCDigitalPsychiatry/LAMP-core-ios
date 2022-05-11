//
//  FileStorage.swift
//  mindLAMP Consortium
//
//  Created by Zco Engineer on 18/03/20.
//

import Foundation

public class FileStorage {
    
    fileprivate init() { }
    
    enum Directory {
        case documents
        case caches
    }
    
    /// Returns URL constructed from specified directory
    static fileprivate func getURL(for directory: Directory) -> URL {
        var searchPathDirectory: FileManager.SearchPathDirectory
        
        switch directory {
        case .documents:
            searchPathDirectory = .documentDirectory
        case .caches:
            searchPathDirectory = .cachesDirectory
        }
        
        if let url = FileManager.default.urls(for: searchPathDirectory, in: .userDomainMask).first {
            return url
        } else {
            fatalError("Could not create URL for specified directory!")
        }
    }
    
    static private func createDirectory(_ urlPath: URL) {
        do {
            try FileManager.default.createDirectory(atPath: (urlPath.path), withIntermediateDirectories: true, attributes: [kCFURLIsExcludedFromBackupKey as FileAttributeKey: true])
        } catch let error as NSError {
            printError(error.localizedDescription)
        }
    }
    
    /// Create custom directory.
    ///
    /// - Parameters:
    ///   - name: name of custom directory.
    ///   - directory: directory where custom directory is created.
    static func createDirectory(name: String, in directory: Directory) {
        if !fileExists(name, in: directory) {
            let url = getURL(for: directory).appendingPathComponent(name)
            createDirectory(url)
        }
    }

    /// Store an encodable struct to the specified directory on disk
    ///
    /// - Parameters:
    ///   - object: the encodable struct to store
    ///   - directory: where to store the struct
    ///   - fileName: what to name the file where the struct data will be stored
    static func store<T: Encodable>(_ object: T, to folder: String?, in directory: Directory, as fileName: String) {
        var url = getURL(for: directory)
        if let dirName = folder {
            createDirectory(name: dirName, in: directory)
            url.appendPathComponent(dirName, isDirectory: true)
        }
        url.appendPathComponent(fileName, isDirectory: false)
        
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
        } catch {
            printToFile("store file \(error.localizedDescription)")
            print(error.localizedDescription)
        }
    }
    
    /// Retrieve and convert a struct from a file on disk
    ///
    /// - Parameters:
    ///   - fileName: name of the file where struct data is stored
    ///   - directory: directory where struct data is stored
    ///   - type: struct type (eg. LogsData.self)
    /// - Returns: decoded struct model(s) of data
    static func retrieve<T: Decodable>(_ fileName: String, from folder: String?, in directory: Directory, as type: T.Type) -> T? {
        var url = getURL(for: directory)
        if let dirName = folder {
            url.appendPathComponent(dirName, isDirectory: true)
        }
        url.appendPathComponent(fileName, isDirectory: false)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            return nil
        }
        
        if let data = FileManager.default.contents(atPath: url.path) {
            let decoder = JSONDecoder()
            do {
                let model = try decoder.decode(type, from: data)
                return model
            } catch {
                print(error.localizedDescription)
                return nil
            }
        } else {
            printToFile("retrieve file content no data")
            print("No data at \(url.path)!")
            return nil
        }
    }
    
    static func retrieve(_ fileName: String, from folder: String?, in directory: Directory) -> Data? {
        var url = getURL(for: directory)
        if let dirName = folder {
            url.appendPathComponent(dirName, isDirectory: true)
        }
        url.appendPathComponent(fileName, isDirectory: false)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            return nil
        }
        return FileManager.default.contents(atPath: url.path)
    }
    
    /// Remove all files at specified folder in/or directory.
    static func clear(_ folder: String?, in directory: Directory) {
        var url = getURL(for: directory)
        if let dirName = folder {
            url.appendPathComponent(dirName, isDirectory: true)
        }
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            for fileUrl in contents {
                try FileManager.default.removeItem(at: fileUrl)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Remove specified file from specified directory
    static func remove(_ fileName: String, from folder: String?, in directory: Directory) {
        var url = getURL(for: directory)
        if let dirName = folder {
            url.appendPathComponent(dirName, isDirectory: true)
        }
        url.appendPathComponent(fileName, isDirectory: false)
        
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    /// Returns BOOL indicating whether file exists at specified directory with specified file name
    static func fileExists(_ fileName: String, in directory: Directory) -> Bool {
        let url = getURL(for: directory).appendingPathComponent(fileName, isDirectory: false)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    static func urls(for folder: String?, in directory: Directory, skipsHiddenFiles: Bool = true ) -> [URL]? {
        
        var url = getURL(for: directory)
        if let dirName = folder {
            url.appendPathComponent(dirName, isDirectory: true)
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [])
            return fileURLs
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
