// mindLAMP

import Foundation

enum VideoUploadAPIError: Error, LocalizedError {
    case invalidURL
    case badStatus(code: Int, body: String?)
    case decodingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid upload API URL."
        case let .badStatus(code, body):
            return "Upload API error (\(code)): \(body ?? "")"
        case let .decodingFailed(err):
            return "Could not read upload response: \(err.localizedDescription)"
        }
    }
}

/// REST client for participant video multipart upload control plane.
struct VideoUploadAPIClient: Sendable {
    private let configuration: VideoDiary.VideoUploadConfiguration
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(configuration: VideoDiary.VideoUploadConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    private func endpoint(_ path: String) throws -> URL {
        guard let url = URL(string: path, relativeTo: configuration.apiBaseURL)?.absoluteURL else {
            throw VideoUploadAPIError.invalidURL
        }
        return url
    }

    private func applyCommonHeaders(to request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let auth = configuration.authorizationHeaderValue {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }
    }

    private func postJSON<T: Encodable, R: Decodable>(_ path: String, body: T) async throws -> R {
        var request = URLRequest(url: try endpoint(path))
        request.httpMethod = "POST"
        applyCommonHeaders(to: &request)
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw VideoUploadAPIError.badStatus(code: -1, body: nil)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8)
            throw VideoUploadAPIError.badStatus(code: http.statusCode, body: text)
        }
        do {
            return try decoder.decode(R.self, from: data)
        } catch {
            throw VideoUploadAPIError.decodingFailed(underlying: error)
        }
    }

    func initiate(body: VideoUploadInitiateRequestBody) async throws -> VideoUploadInitiateResponse {
        let path = "/participant/\(configuration.participantId)/video/upload/initiate"
        return try await postJSON(path, body: body)
    }

    func complete(body: VideoUploadCompleteRequestBody) async throws -> VideoUploadCompleteResponse {
        let path = "/participant/\(configuration.participantId)/video/upload/complete"
        return try await postJSON(path, body: body)
    }

    func refreshURLs(body: VideoUploadRefreshURLsRequestBody) async throws -> VideoUploadRefreshURLsResponse {
        let path = "/participant/\(configuration.participantId)/video/upload/refresh-urls"
        return try await postJSON(path, body: body)
    }

    func abort(body: VideoUploadAbortRequestBody) async throws {
        let path = "/participant/\(configuration.participantId)/video/upload/abort"
        var request = URLRequest(url: try endpoint(path))
        request.httpMethod = "POST"
        applyCommonHeaders(to: &request)
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw VideoUploadAPIError.badStatus(code: -1, body: nil)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8)
            throw VideoUploadAPIError.badStatus(code: http.statusCode, body: text)
        }
    }
}
