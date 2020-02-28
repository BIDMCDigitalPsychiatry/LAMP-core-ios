//
//  NodeManager.swift
//  lampv2
//
//  Created by ZCo Engg Dept on 03/01/20.
//  Copyright © 2020 lamp. All rights reserved.
//

import Foundation

class NodeManager {
    
    static let shared = NodeManager()
    
    let fileManager = FileManager.default
    var canCallApi: Bool = false
    
    private init() {  }

    
    func startNodeServer() {
        
        //createNodeFolder()
        copyNodeFiles()
        
        let nodeThread = Thread(target: self, selector: #selector(startNodeThread), object: nil)
        // Set 2MB of stack space for the Node.js thread.
        nodeThread.stackSize = 2*1024*1024
        nodeThread.start()
        
    }
    
    func getServerStatus() {
        if let localNodeServerURL = URL(string: "http:/127.0.0.1:5000/status") {
            var request = URLRequest(url: localNodeServerURL)
            request.httpMethod = "GET"
            
            let session = URLSession.shared
            
            session.dataTask(with: request) { (data, response, error) in
                if let response = response {
                    print(response)
                }
                if let data = data {
                    if let str = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            if (str == "ok") {
                                print("Node server is running")
                                self.canCallApi = true
                            }
                        }
                    }
                }
            }.resume()
        }
    }
    
    func callServerAndGetResponse() {
        
        if (!canCallApi) {
            return
        }
        
        if let localNodeServerURL = URL(string: "http:/127.0.0.1:5000/postapi") {
            let parameterDictionary = ["username" : "Test", "password" : "123456"]
            var request = URLRequest(url: localNodeServerURL)
            request.httpMethod = "POST"
            request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
            
            guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
                return
            }
            request.httpBody = httpBody
            
            let session = URLSession.shared
            session.dataTask(with: request) { (data, response, error) in
                if let response = response {
                    print(response)
                }
                
                if let data = data {
                    if let str = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            print(str)
                        }
                    }
                }
            }.resume()
        }
    }

}

//MARK: - private

private extension NodeManager {
       
    @objc func startNodeThread() {
        
        let srcPath = FileManager.homeURL.path + "/index.js"
        let nodeArguments = ["node", srcPath]
        NodeRunner.startEngine(withArguments: nodeArguments as [Any])
    }
    
    func copyNodeFiles() {
        
        let nodeFolder = FileManager.nodeFolder
        let destPath = FileManager.homeURL.path
        if (!FileManager.default.fileExists(atPath: destPath)) {
            copyFileToDocumentsFolder(relativePath: nodeFolder, destPath: destPath)
        } else {
            print("File exist: \(nodeFolder)")
        }
    }
    
    func copyFileToDocumentsFolder(relativePath: String, destPath: String) {
        
        guard let srcPath = Bundle.main.path(forResource: relativePath, ofType: nil) else {
            print("Error: \(relativePath) not found in main bundle!")
            return
        }
        
        do {
            try fileManager.copyItem(at: URL(fileURLWithPath: srcPath), to: URL(fileURLWithPath: destPath))
            print("Copied file: \(relativePath)")
        } catch let error as NSError {
            print("errors" + error.description)
        }
    }
}
