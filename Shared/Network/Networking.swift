// watchkitapp Extension

import Foundation

public class Networking: NSObject, NetworkingAPI {
    
    let session: URLSession
    let baseURL: URL
    var currentTask: URLSessionTask?
    
    //https://developer.apple.com/documentation/watchkit/keeping_your_watchos_content_up_to_date
    public init(baseURL: URL, isBackgroundSession: Bool) {
        self.baseURL = baseURL
        if isBackgroundSession {
            let config = URLSessionConfiguration.background(withIdentifier: "MySession")
            self.session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        } else {
            self.session = URLSession.shared
        }
    }
    
    public func cancelServiceCall() {
        currentTask?.cancel()
    }
    
    public func makeWebserviceCall<T: Decodable>(with request: RequestProtocol, then callback: @escaping (Result<T>) -> Void) {
        
        let method = request.requestTye
        //create url request
        guard let requestURL = URL(string: "\(baseURL)\(request.buildEndpoint())") else {
            callback(Result<T>.failure(NetworkError.invalidURL))
            return
        }
        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = method.getTypeString()
        //set header fields according to content type
        urlRequest.allHTTPHeaderFields = request.getRequestHeaders()
        urlRequest.timeoutInterval = 30
        
        switch method {
            
        case .post, .put:
            
            print("requestURL = \(requestURL)")
            print("headers = \(String(describing: urlRequest.allHTTPHeaderFields))")
            if let data = request.jsonData {
                urlRequest.httpBody = data
                print("body Json: \(String(describing: String(data: data, encoding: String.Encoding.utf8)))")
            }
            
        case .get:
            print("requestURL = \(requestURL)")
            print("headers = \(String(describing: urlRequest.allHTTPHeaderFields))")
            ()
        case .delete:
            ()
        }
        
        sendRequest(urlRequest, completion: callback)
    }
    
    private func sendRequest<T: Decodable>(_ request: URLRequest, completion: @escaping (Result<T>) -> Void) {
        currentTask = session.dataTask(with: request) { (data, response, error) in
            
            self.logResponse(data, response, error)
            
            if let err = error {
                completion(.failure(err))
                return
            }

            if let dataResp = data {
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
                dateFormatter.locale =  Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
                
                let decoder = JSONDecoder()
                let formatter = dateFormatter
                decoder.dateDecodingStrategy = .formatted(formatter)
                do {
                    let responseData = try decoder.decode(Safe<T>.self, from: dataResp)
                    completion(.success(responseData.value))
                } catch (let err) {
                    completion(.failure(err))
                }

            } else {
                
                if let httpResponse = response as? HTTPURLResponse {
                    let status = httpResponse.statusCode
                    guard (200...299).contains(status) else {
                        let errorMsg = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                        completion(.failure(NetworkError.errorResponse(errorMsg)))
                        return
                    }
                }
                completion(.failure(NetworkError.noResponse))
            }
        }
        
        currentTask?.resume()
    }
    
    /// log the responsees
    ///
    /// - Parameters:
    ///   - data:
    ///   - response:
    ///   - error:
    private func logResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        //#if DEBUG
        print("httpResponse = \(String(describing: response))")
        print("error = \(String(describing: error))")
        
        do {
            if let dataResp = data {
                let jsonResult: AnyObject = try JSONSerialization.jsonObject(with: dataResp, options:
                    JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
                print("response=\(jsonResult)")
            }
        } catch {
            
        }
    }
}

extension Networking: URLSessionDelegate {
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("finished")
    }
}
