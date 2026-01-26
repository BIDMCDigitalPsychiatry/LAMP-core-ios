final class TokenManager {
    static let shared = TokenManager()
    
    private init() {}
    
    var accessToken: String?
    var refreshToken: String?

    func updateTokens(access: String, refresh: String) {
        self.accessToken = access
        self.refreshToken = refresh
    }

    /// Actual refresh call
    func refreshAccessToken(baseURL: URL,
                            session: URLSession,
                            completion: @escaping (Result<String, Error>) -> Void) {

        guard let refreshToken = self.refreshToken else {
            completion(.failure(NSError(domain: "NoRefreshToken", code: 0)))
            return
        }

        var url = baseURL
        url.appendPathComponent("renewToken")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken ?? "")", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["refreshToken": refreshToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error { return completion(.failure(error)) }

            guard let data = data else {
                return completion(.failure(NSError(domain: "NoData", code: 0)))
            }

            struct Response: Decodable {
                let token: String
            }

            do {
                let decoded = try JSONDecoder().decode(Response.self, from: data)
                self.accessToken = decoded.token
                completion(.success(decoded.token))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}