// mindLAMP
import Foundation

actor TokenManager {
    static let shared = TokenManager()

    private init() {
        self.accessToken = Endpoint.getBearerAccessToken()
        self.refreshToken = Endpoint.getBearerRefreshToken()
    }

    private var accessToken: String?
    private var refreshToken: String?
    private var isRefreshing = false
    private var waiters: [(Result<String>) -> Void] = []

    func updateTokens(access: String?, refresh: String?) {
        self.accessToken = access
        self.refreshToken = refresh
        Endpoint.setBearerRefreshToken(refresh)
        print("Done updateTokens")
    }

    /// Ensures only one refresh runs at a time
    func refreshAccessToken(
        baseURL: URL,
        session: URLSession,
        completion: @escaping (Result<String>) -> Void
    ) {

        // If already refreshing → queue the completion
        if isRefreshing {
            waiters.append(completion)
            return
        }

        isRefreshing = true
        waiters.append(completion)

        guard let refreshToken else {
            finishAll(.failure(NSError(domain: "NoRefreshToken", code: 0)))
            return
        }

        var url = baseURL
        url.appendPathComponent("renewToken")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken ?? "")", forHTTPHeaderField: "Authorization")

        let body = ["refreshToken": refreshToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        print("getting refresh token")
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            Task { await self?.handleRefreshResponse(data: data, error: error) }
        }
        task.resume()
    }

    private func handleRefreshResponse(data: Data?, error: Error?) {
        if let error {
            print("error = \(error)")
            finishAll(.failure(error))
            return
        }

        guard let data else {
            print("NoData")
            finishAll(.failure(NSError(domain: "NoData", code: 0)))
            return
        }

        struct Response: Decodable {
            struct TokenData: Decodable {
                var access_token: String
                var refresh_token: String
            }
            var data: TokenData
        }

        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)

            accessToken = decoded.data.access_token
            refreshToken = decoded.data.refresh_token
            print("got token = \(accessToken!)")
            Endpoint.setToken(decoded.data.access_token, for: .bearer)
            Endpoint.setBearerRefreshToken(decoded.data.refresh_token)

            finishAll(.success(decoded.data.access_token))
        } catch {
            print("parse error = \(error)")
            finishAll(.failure(error))
        }
    }

    private func finishAll(_ result: Result<String>) {
        isRefreshing = false
        let callbacks = waiters
        waiters.removeAll()

        for cb in callbacks {
            cb(result)
        }
    }
}
