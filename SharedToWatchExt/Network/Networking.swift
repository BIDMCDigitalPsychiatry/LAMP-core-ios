// watchkitapp Extension

import Foundation
import LAMP

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
            
            print("\nrequestURL = \(requestURL)")
            //print("\nheaders = \(String(describing: urlRequest.allHTTPHeaderFields))")
            if let data = request.jsonData {
                urlRequest.httpBody = data
                print("body Json: \(String(describing: String(data: data, encoding: String.Encoding.utf8)))")
            } else if let data = request.jsonBody {
                do {
                    print("jsonBody = \(data)")
                    let jsonData = try JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions.prettyPrinted)
                    urlRequest.httpBody = jsonData

                } catch let err {
                    callback(.failure(err))
                    return
                }
            } else {
                print("no body?")
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
    
    private func sendRequest<T: Decodable>(
        _ request: URLRequest,
        completion: @escaping (Result<T>) -> Void
    ) {

        func perform(_ req: URLRequest) {
            currentTask = session.dataTask(with: req) { data, response, error in

                Networking.logResponse(data, response, error)

                if let err = error {
                    completion(.failure(err))
                    return
                }

                // Check HTTP status
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 401 {
                    
                    print(" 401 → refresh token")

                    // ⬇️ FIX: You must wrap async call in Task
                    Task {
                        await self.handle401AndRetry(
                            originalRequest: req,
                            completion: completion
                        )
                    }
                    return
                }

                // Normal decode handling
                guard let dataResp = data else {
                    completion(.failure(NetworkError.noResponse))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let formatter = OpenISO8601DateFormatter()
                    decoder.dateDecodingStrategy = .formatted(formatter)

                    let responseData = try decoder.decode(Safe<T>.self, from: dataResp)
                    completion(.success(responseData.value))
                } catch {
                    completion(.failure(error))
                }
            }
            
            currentTask?.resume()
        }

        // ⬇️ perform should NOT be async
        perform(request)
    }
    
    private func handle401AndRetry<T: Decodable>(
        originalRequest: URLRequest,
        completion: @escaping (Result<T>) -> Void
    ) async {
        
        await TokenManager.shared.refreshAccessToken(baseURL: baseURL, session: session) { result in
            switch result {
            case .failure(let err):
                completion(.failure(err))

            case .success(let newToken):
                // Rebuild request with updated Bearer
                var retryRequest = originalRequest
                retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")

                // Retry the original request with new token
                let retryTask = self.session.dataTask(with: retryRequest) { data, response, error in

                    print("response with new token")
                    Networking.logResponse(data, response, error)

                    if let error = error {
                        return completion(.failure(error))
                    }

                    guard let data else {
                        return completion(.failure(NetworkError.noResponse))
                    }

                    do {
                        let decoder = JSONDecoder()
                        let formatter = OpenISO8601DateFormatter()
                        decoder.dateDecodingStrategy = .formatted(formatter)

                        let responseData = try decoder.decode(Safe<T>.self, from: data)
                        completion(.success(responseData.value))
                    } catch {
                        completion(.failure(error))
                    }
                }

                retryTask.resume()
            }
        }
    }
    
    /// log the responsees
    ///
    /// - Parameters:
    ///   - data:
    ///   - response:
    ///   - error:
    static func logResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        #if DEBUG
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
        #endif
    }
}

extension Networking: URLSessionDelegate {
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("finished")
    }
}
