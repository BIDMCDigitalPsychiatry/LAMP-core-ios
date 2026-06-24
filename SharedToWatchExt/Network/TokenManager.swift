// mindLAMP
import Foundation

extension Notification.Name {
    /// Posted when the refresh token is rejected by the server (or missing), so
    /// the session can no longer be renewed and the user must log in again.
    /// Observed by the app layer to clear session state and present login.
    static let lampSessionExpired = Notification.Name("lampSessionExpired")
}

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
    }

    /// Ensures only one refresh runs at a time. Concurrent callers (e.g. several
    /// background upload workers) are queued and all resolved with the single
    /// refresh result, so the rotating refresh token is never clobbered.
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
            // No refresh token at all → the session cannot be renewed.
            sessionDidExpire()
            finishAll(.failure(NSError(domain: "NoRefreshToken", code: 0)))
            return
        }

        // Server route is POST /mobile-token/refresh (LAMP-server
        // CredentialService.ts). Append as separate components so the path
        // separator is not percent-encoded.
        var url = baseURL
        url.appendPathComponent("mobile-token")
        url.appendPathComponent("refresh")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // The refresh token is verified from the body; this endpoint must be
        // callable with an expired access token, so no Authorization header.
        let body = ["refreshToken": refreshToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            Task { await self?.handleRefreshResponse(data: data, response: response, error: error) }
        }
        task.resume()
    }

    private func handleRefreshResponse(data: Data?, response: URLResponse?, error: Error?) {
        // Transient network error → keep tokens so the next attempt can retry.
        if let error {
            finishAll(.failure(error))
            return
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        // Server returns 400 {"error":"400.invalid-refresh-token"} when the
        // refresh token is no longer valid → the session is dead, force re-login.
        if statusCode == 400 || statusCode == 401 {
            sessionDidExpire()
            finishAll(.failure(NSError(domain: "InvalidRefreshToken", code: statusCode)))
            return
        }

        guard let data else {
            finishAll(.failure(NSError(domain: "NoData", code: 0)))
            return
        }

        // Success body is flat camelCase: {"accessToken":"...","refreshToken":"..."}
        // (LAMP-server auth.ts createMobileTokens → res.json(newTokens)). The
        // refresh token ROTATES on every call, so the new one MUST be persisted
        // or the next refresh will 400.
        struct Response: Decodable {
            var accessToken: String
            var refreshToken: String
        }

        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)

            accessToken = decoded.accessToken
            refreshToken = decoded.refreshToken
            Endpoint.setToken(decoded.accessToken, for: .bearer)
            Endpoint.setBearerRefreshToken(decoded.refreshToken)

            finishAll(.success(decoded.accessToken))
        } catch {
            finishAll(.failure(error))
        }
    }

    /// Clears bearer tokens and notifies the app layer that the user must
    /// re-authenticate. The observer (app layer) is responsible for presenting
    /// login on the main thread.
    private func sessionDidExpire() {
        accessToken = nil
        refreshToken = nil
        Endpoint.setBearerRefreshToken(nil)
        Endpoint.setToken(nil, for: .bearer)
        NotificationCenter.default.post(name: .lampSessionExpired, object: nil)
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
