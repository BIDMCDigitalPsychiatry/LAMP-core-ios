// mindLAMP

import Foundation
//import CryptoSwift
//import MONetworking

protocol DownloadStatus: class {
    func setProgressText(_ text: String)
    func downloadCompleted(isSuccess: Bool)
}

enum Dashboard {
    struct Request: Encodable {
        
    }
    
    struct Response: Decodable {
        let url: String
        let version: String //"1.1";
        let launchURL: String //"http://127.0.0.1:5000/login";
        let nodeJSPath: String //"nodejs-project/index.js";
        let nodeRootFolder: String //"nodejs-project";
    }
}

class VersionCheckViewModel {
    
    let connection: NetworkingAPI = NetworkConfig.dashboardAPI()
    let key = "TODO: obfuscate the key and set here" // length == 32
    
    weak var delegate: DownloadStatus?
    
    private func encryptText(_ text: String, iv: String) -> String? {
        do {
            let data = text.data(using: .utf8)
            let encodedData = try data?.aesEncrypt(key: key, iv: iv)
            return encodedData!.base64EncodedString()
        } catch {
            return nil
        }
    }
    
    func downloadDashboard(_ fromURL: String) {
        
        let fileDownload = FileDownloader(previousRootFolder: UserDefaults.standard.nodeRootFolder)
        fileDownload.delegate = self
        guard let url = URL(string: fromURL) else {
            delegate?.downloadCompleted(isSuccess: false)
            return
        }
        fileDownload.download(from: url)
    }
    
    func getDownloadURL(completion: @escaping (Dashboard.Response?, Error?) -> Void) {
        let deviceid = ""//TODO: get device id
        let iv = randomString(length: 16)//length == 16
        guard let encrypted = encryptText(deviceid, iv: iv) else {
            return
        }
        let authHeader = "Basic \(encrypted)"
        let dictHeaders = ["Authorization": authHeader, "device_id": deviceid, "iv": iv]
        let data = RequestData(endpoint: Endpoint.getLatestDashboard.rawValue, requestTye: HTTPMethodType.get, headers: dictHeaders)
        print("getDownloadURL")
        connection.makeWebserviceCall(with: data) { (response: Result<Dashboard.Response>) in
            switch response {
            case .failure(let err):
                DispatchQueue.main.async {
                    completion(nil, err)
                }
                break
            case .success(let response):
                DispatchQueue.main.async {
                    completion(response, nil)
                }
                
                break
            }
        }
    }
    
    func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

// MARK: DownloadDelegate
extension VersionCheckViewModel: DownloadDelegate {
    
    func didComplete(percentage: Int64) {
        print("percentage = \(percentage)")
        if percentage > 0 {
            delegate?.setProgressText("Downloading...\(percentage)%")
        } else {
            delegate?.setProgressText("Downloading...")
        }
    }
    
    func didCompleteBytes(mbString: String) {
        delegate?.setProgressText("Downloading...\(mbString) MB")
    }
    
    func didFinishEvents(isSuccess: Bool) {
        delegate?.downloadCompleted(isSuccess: isSuccess)
    }
}

extension Data {
    func aesEncrypt(key: String, iv: String) throws -> Data{
        //+roll
//        let encypted = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes), padding: .pkcs7).encrypt(self.bytes)
//        return Data(encypted)
        return Data(base64Encoded: "")!
    }
    
    func aesDecrypt(key: String, iv: String) throws -> Data {
        //+roll
//        let decrypted = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes), padding: .pkcs7).decrypt(self.bytes)
//        return Data(decrypted)
        return Data(base64Encoded: "")!
    }
}

