//
//  Networking.swift
//  lampv2
//
//  Created by ZCO Engineer on 07/04/16.
//

import UIKit

final class Networking {

    let session: URLSession
    let baseURL: URL
    var currentTask: URLSessionTask?

    init(baseURL: URL, session: URLSession = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
    }
    class func setNetWorkIndicatorVisible(_ toggle: Bool) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = toggle
        }
    }
    
    static let baseDirectoryURL: URL? = {
        guard let docPath =  NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return nil
        }
        let ourDirectoryPath = docPath.appending("/LampV2")
        // so simply makes a directory called "YourCompanyName"
        // which will be there for all time, for your use
        var ocb: ObjCBool = true
        let exists = FileManager.default.fileExists(atPath: ourDirectoryPath, isDirectory: &ocb)
        
        if !exists {
            do {
                try FileManager.default.createDirectory(atPath: ourDirectoryPath, withIntermediateDirectories: false, attributes: nil)
                print("we did create our Image Directory, for the first time.")
                // never need to again
                return URL(fileURLWithPath: ourDirectoryPath)
            } catch {
                print(error.localizedDescription)
                print("disaster trying to make our Image Directory?")
                return nil
            }
        } else {
            // already exists, as usual.
            return URL(fileURLWithPath: ourDirectoryPath)
        }
    }()
}

extension Networking: NetworkingAPI {

    func cancelServiceCall() {
        currentTask?.cancel()
    }
    
    func makeWebserviceCall<T: Decodable>(with request: RequestProtocol, then callback: @escaping (Result<T>) -> Void) {

        let method = request.requestTye
        //check internet reachability
        /*if ReachabilityManager.sharedInstance.isReachable() == false {
            callback(Result<T>.failure(LMError(.definedError(.noReachability))))
            return
        }*/

        //show network indicator
        Networking.setNetWorkIndicatorVisible(true)

        //create url request
        guard let requestURL = URL(string: "\(baseURL)\(request.buildEndpoint())") else {
            callback(Result<T>.failure(LMError(.definedError(.jsonParsingFailed))))
            return
        }
        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = method.getTypeString()
        printToFile("Request URL...: \(urlRequest)")
        //set header fields according to content type
        urlRequest.allHTTPHeaderFields = request.getRequestHeaders()
        urlRequest.timeoutInterval = 30

        switch method {
            
        case .post, .put:
            if let multiPartFields = request.getMultiPartDetails() {
                
                guard let requestData = createMultipartData(multiPartFields: multiPartFields) else {
                    Networking.setNetWorkIndicatorVisible(false)
                    callback(.failure(LMError(.definedError(.jsonParsingFailed))))
                    return
                }
                urlRequest.httpBody = requestData
                
            } else {
                if let data = request.jsonData {
                    urlRequest.httpBody = data
                    printToFile("Parameter Json: \(String(describing: String(data: data, encoding: String.Encoding.utf8)))")
                } else {
                    //to support JSON request
                    if let jsonBody = request.jsonBody {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: jsonBody, options: JSONSerialization.WritingOptions.prettyPrinted)
                            urlRequest.httpBody = jsonData
                            printToFile("Parameter Json: \(String(describing: String(data: jsonData, encoding: String.Encoding.utf8)))")
                        } catch {
                            Networking.setNetWorkIndicatorVisible(false)
                            callback(.failure(LMError(.definedError(.jsonParsingFailed))))
                            return
                        }
                    } else {

                        Networking.setNetWorkIndicatorVisible(false)
                        callback(.failure(LMError(.definedError(.jsonParsingFailed))))
                        return
                    }
                }
            }
        case .get:
            ()
        case .delete:
            ()
        }

        printToFile("request: \(urlRequest), headers = \(String(describing: urlRequest.allHTTPHeaderFields))")

        if let fileExt = request.downloadFileType {
            downloadRequest(fileExt, request.downloadFileName, urlRequest, completion: callback)
        } else {
            sendRequest(urlRequest, completion: callback)
        }
    }
    
    private func downloadRequest<T: Decodable>(_ fileExt: String, _ fileNam: String?, _ request: URLRequest, completion: @escaping (Result<T>) -> Void) {
        currentTask = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            self.logResponse(nil, response, error)
            if let errorResponse = self.checkForNetworkError(error, InResponse: response) {
                Networking.setNetWorkIndicatorVisible(false)
                if errorResponse.isLoggedOut {
//                    AppController.shared.logoutWithError(errorResponse)
                    completion(.failure(errorResponse))
                    return
                }
                completion(.failure(errorResponse))
                return
            }
            guard let localURL = tempLocalUrl else {
                Networking.setNetWorkIndicatorVisible(false)
                completion(.failure(LMError(.definedError(.webServiceResponseIsNil))))
                return
            }
            guard let destinationPath = Networking.baseDirectoryURL else {
                Networking.setNetWorkIndicatorVisible(false)
                completion(.failure(LMError.init(ErrorKind.customError(0), msg: "Unable to retrieve file!")))
                return
            }
            let fileName: String
            if let file = fileNam {
                fileName = file
            } else {
                fileName = Date().toDisplayString(format: DateFormats.fileName)
            }
            let destinationFilePath = destinationPath.appendingPathComponent(fileName).appendingPathExtension(fileExt)
            do {
                try FileManager.default.removeItem(at: destinationFilePath)
            } catch {
            }
            do {
                try FileManager.default.moveItem(at: localURL, to: destinationFilePath)
                
                printToFile("destinationFilePath = \(destinationFilePath.absoluteString)")
                guard let contentData = "{\"filePath\" : \"\(destinationFilePath.path)\"}".data(using: .utf8) else {
                    Networking.setNetWorkIndicatorVisible(false)
                    completion(.failure(LMError.init(ErrorKind.customError(0), msg: "Unable to retrieve file!")))
                    return
                }
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(T.self, from: contentData)
                completion(.success(decodedData))
                
            } catch let writeError {
                completion(.failure(LMError.errorFromErr(writeError)))
            }
            Networking.setNetWorkIndicatorVisible(false)
        }
        currentTask?.resume()
    }

    private func sendRequest<T: Decodable>(_ request: URLRequest, completion: @escaping (Result<T>) -> Void) {

        currentTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in

            self.logResponse(data, response, error)

            if let errorResponse = self.checkForNetworkError(error, InResponse: response) {

                Networking.setNetWorkIndicatorVisible(false)
                if errorResponse.isLoggedOut {
//                    AppController.shared.logoutWithError(errorResponse)
                    completion(.failure(errorResponse))
                    return
                }
                completion(.failure(errorResponse))
                return
            }

            if let dataResp = data {
                do {
                    Networking.setNetWorkIndicatorVisible(false)
                    let decoder = JSONDecoder()
                    let formatter = Date.jsonDateDecodeFormatter
                    decoder.dateDecodingStrategy = .formatted(formatter)
                    let responseData = try decoder.decode(Safe<T>.self, from: dataResp)
                    completion(.success(responseData.value))
                    return
                } catch let error {
                    Networking.setNetWorkIndicatorVisible(false)
                    if let err = error as? LMError {
                        if err.isLoggedOut {
                            //copy
//                            AppController.shared.logoutWithError(err)
                            completion(.failure(err))
                            return
                        }
                        completion(.failure(err))
                    } else {
                        completion(.failure(LMError(.definedError(.jsonParsingFailed))))
                    }
                    printError("Serialization error: \(error)")
                }
            } else {
                Networking.setNetWorkIndicatorVisible(false)
                completion(.failure(LMError(.definedError(.webServiceResponseIsNil))))
            }
        })

        currentTask?.resume()
    }

    // MARK: - Private functions

    /// <#Description#>
    ///
    /// - Parameters:
    ///   - multiPartFields: <#multiPartFields description#>
    ///   - jsonBody: <#jsonBody description#>
    /// - Returns: <#return value description#>
    private func createMultipartData(multiPartFields: MultiPartFields) -> Data? {

        let boundryString: String = ContentTypeConstants.boundryString
        var requestData: Data = Data()

        //requestData.append("\r\n".toData())

        for fileData in multiPartFields.fileContent {
            
            requestData.append("\r\n--\(boundryString)\r\n".toData())
            
            if let key = fileData.key, let value = fileData.value {
                requestData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".toData())
                requestData.append(value.toData())
                requestData.append("\r\n--\(boundryString)\r\n".toData())
            }
            
            requestData.append("Content-Disposition: form-data; name=\"\(fileData.name)\"; filename=\"\(fileData.filename ?? "")\"\r\n".toData())
            requestData.append("Content-Type: image/jpeg\r\n\r\n".toData())
            requestData.append(fileData.imageData)
            //requestData.append("\r\n".toData())
        }

        requestData.append("\r\n--\(boundryString)--\r\n".toData())

        return requestData
    }
    /// check for network errors
    ///
    /// - Parameters:
    ///   - error:
    ///   - response:
    /// - Returns: LMError if any error found
    private func checkForNetworkError(_ error: Error?, InResponse response: URLResponse?) -> LMError? {
        if let err = error {
            // You can handle error response here
            Networking.setNetWorkIndicatorVisible(false)
            if (err as NSError).code == -999 {
                return LMError(.networkError(-999))
            }
            return LMError.errorFromErr(err)

        }

        if let httpResponse = response as? HTTPURLResponse {
            let status = httpResponse.statusCode

            // HTTP 2xx codes only, please!
            guard (200...299).contains(status) else {

                Networking.setNetWorkIndicatorVisible(false)
                return LMError(.networkError(status))
            }
        }
        return nil
    }

    /// log the responsees
    ///
    /// - Parameters:
    ///   - data:
    ///   - response:
    ///   - error:
    private func logResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        //#if DEBUG
            printDebug("httpResponse = \(String(describing: response))")
            printDebug("error = \(String(describing: error))")

            do {
                if let dataResp = data {
                    let jsonResult: AnyObject = try JSONSerialization.jsonObject(with: dataResp, options:
                        JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
                    printDebug("response=\(jsonResult)")
                }
            } catch {

            }
        //#endif
        if Logging.isLogToFile {
            printToFile("httpResponse = \(String(describing: response))")
            printToFile("error = \(String(describing: error))")

            do {
                if let dataResp = data {
                    let jsonResult: AnyObject = try JSONSerialization.jsonObject(with: dataResp, options:
                        JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
                    printToFile("response=\(jsonResult)")
                }
            } catch let err {
                printToFile(err.localizedDescription)
            }
        }
    }
}
