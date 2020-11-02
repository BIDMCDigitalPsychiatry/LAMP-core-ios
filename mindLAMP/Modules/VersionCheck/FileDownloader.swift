// mindLAMP

import Foundation
import UIKit
//import ZIPFoundation

protocol DownloadDelegate: class {
    func didComplete(percentage: Int64)
    func didCompleteBytes(mbString: String)
    func didFinishEvents(isSuccess: Bool)
}

class FileDownloader: NSObject {
    
    weak var delegate: DownloadDelegate?
    private var previousRootFolder: String
    init(previousRootFolder: String?) {
        self.previousRootFolder = previousRootFolder ?? "nodejs-project"
    }
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.lamp.digital.Download")
        config.sharedContainerIdentifier = "group.com.lamp.digital.Download"
        let operationQueue = OperationQueue()
        return URLSession(configuration: config, delegate: self, delegateQueue: operationQueue)
    }()
    
    // MARK: fetch file from url
    func download(from url: URL) {
        
        let downloadTask = urlSession.downloadTask(with: url)
        downloadTask.resume()
    }
}

extension FileDownloader: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("urlSessionDidFinishEvents")
        DispatchQueue.main.async {
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            appdelegate.completionHandler?()
            appdelegate.completionHandler = nil
        }
    }
}

extension FileDownloader: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        print("download finished to \(location.absoluteString)")
        do {
            let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let savedURL = documentsURL.appendingPathComponent(location.lastPathComponent)
            
            print("moved file to: \(savedURL.absoluteString)")
            
            try FileManager.default.moveItem(at: location, to: savedURL)
            
            var isDir: ObjCBool = true
            let existingFoler = documentsURL.appendingPathComponent(previousRootFolder)
            if FileManager.default.fileExists(atPath: existingFoler.path, isDirectory: &isDir) {
                try FileManager.default.removeItem(at: existingFoler)
            }
            
            //+rolltry FileManager.default.unzipItem(at: savedURL, to: documentsURL)
            
            try FileManager.default.removeItem(at: savedURL)
            
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didFinishEvents(isSuccess: true)
            }
            //let destPath = FileManager.homeURL.path
            
            
        } catch {
            print ("file error: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didFinishEvents(isSuccess: false)
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        print("totalBytesExpectedToWrite = \(totalBytesExpectedToWrite)")
        if totalBytesExpectedToWrite > 0 {
            print("totalBytesWritten = \(totalBytesWritten)")
            let percentDownloaded = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                
            // update the percentage label
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didComplete(percentage: Int64(percentDownloaded * 100.0))
            }
        } else {
            print("totalBytesWritten = \(totalBytesWritten)")
            let mbString = convertBytesToMBString(bytes: totalBytesWritten)
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didCompleteBytes(mbString: mbString)
            }
        }
        
    }


    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
    }
    
    func convertBytesToMBString(bytes: Int64) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
        bcf.countStyle = .file
        return bcf.string(fromByteCount: bytes)
    }
}
