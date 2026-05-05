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

    private func postJSON<T: Encodable, R: Decodable>(_ path: String, body: T, op: String) async throws -> R {
        let url = try endpoint(path)
        logPOSTStart(op: op, url: url, body: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyCommonHeaders(to: &request)
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            videoDiaryUploadLog("\(op): no HTTPURLResponse")
            throw VideoUploadAPIError.badStatus(code: -1, body: nil)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8)
            let preview: String = {
                guard let text else { return "" }
                return text.count > 500 ? String(text.prefix(500)) + "…" : text
            }()
            videoDiaryUploadLog("\(op): HTTP \(http.statusCode) body=\(preview)")
            throw VideoUploadAPIError.badStatus(code: http.statusCode, body: text)
        }
        do {
            let value = try decoder.decode(R.self, from: data)
            logPOSTSuccess(op: op, http: http, data: data)
            return value
        } catch {
            let bodyText = String(data: data, encoding: .utf8).map { String($0.prefix(500)) } ?? ""
            videoDiaryUploadLog("\(op): decode failed \(error) bodyPrefix=\(bodyText)")
            throw VideoUploadAPIError.decodingFailed(underlying: error)
        }
    }

    /// POST with no decoded response (empty body or opaque JSON).
    private func postJSONNoResponse<T: Encodable>(_ path: String, body: T, op: String) async throws {
        let url = try endpoint(path)
        logPOSTStart(op: op, url: url, body: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyCommonHeaders(to: &request)
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            videoDiaryUploadLog("\(op): no HTTPURLResponse")
            throw VideoUploadAPIError.badStatus(code: -1, body: nil)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8)
            videoDiaryUploadLog("\(op): HTTP \(http.statusCode) body=\(text ?? "")")
            throw VideoUploadAPIError.badStatus(code: http.statusCode, body: text)
        }
        logPOSTSuccess(op: op, http: http, data: data)
    }

    func initiate(body: VideoUploadInitiateRequestBody) async throws -> VideoUploadInitiateResponse {
        let path = "/participant/\(configuration.participantId)/video/upload/initiate"
        return try await postJSON(path, body: body, op: "initiate")
    }

    /// Control plane returns no body on success (checksum may be added later).
    func complete(body: VideoUploadCompleteRequestBody) async throws {
        let path = "/participant/\(configuration.participantId)/video/upload/complete"
        try await postJSONNoResponse(path, body: body, op: "complete")
    }

    func refreshURLs(body: VideoUploadRefreshURLsRequestBody) async throws -> VideoUploadRefreshURLsResponse {
        let path = "/participant/\(configuration.participantId)/video/upload/refresh-urls"
        return try await postJSON(path, body: body, op: "refreshURLs")
    }

    func abort(body: VideoUploadAbortRequestBody) async throws {
        let path = "/participant/\(configuration.participantId)/video/upload/abort"
        try await postJSONNoResponse(path, body: body, op: "abort")
    }
}

// MARK: - Logging

private func videoDiaryUploadLog(_ message: String) {
    printDebug("[VideoDiaryUpload] \(message)")
}

private func logEncoder() -> JSONEncoder {
    let enc = JSONEncoder()
    enc.keyEncodingStrategy = .useDefaultKeys
    enc.outputFormatting = [.sortedKeys, .prettyPrinted]
    return enc
}

private func encodeBodyForLog<T: Encodable>(_ body: T) -> String {
    guard let data = try? logEncoder().encode(body),
          let text = String(data: data, encoding: .utf8) else {
        return "{}"
    }
    return text
}

private func prettyJSONString(from data: Data) -> String {
    guard !data.isEmpty else {
        return "(empty)"
    }
    if let obj = try? JSONSerialization.jsonObject(with: data),
       JSONSerialization.isValidJSONObject(obj),
       let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys, .prettyPrinted]),
       let s = String(data: pretty, encoding: .utf8) {
        return s
    }
    if let s = String(data: data, encoding: .utf8) {
        return s.count > 4000 ? String(s.prefix(4000)) + "…" : s
    }
    return "(\(data.count) bytes, non-UTF8)"
}

private func logPOSTStart<T: Encodable>(op: String, url: URL, body: T) {
    let json = encodeBodyForLog(body)
    videoDiaryUploadLog("\(op): POST \(url.absoluteString)\nrequest JSON:\n\(json)")
}

private func logPOSTSuccess(op: String, http: HTTPURLResponse, data: Data) {
    let preview = prettyJSONString(from: data)
    videoDiaryUploadLog("\(op): OK HTTP \(http.statusCode) response JSON:\n\(preview)")
}
