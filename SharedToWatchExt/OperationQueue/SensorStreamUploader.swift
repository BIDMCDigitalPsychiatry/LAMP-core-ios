//  mindLAMP Consortium

#if os(iOS)
import Foundation
import SensorStream
import UIKit

/// Uploads sealed sensor-stream frames to
/// `POST /participant/{id}/sensor-stream` and applies `UploadPolicy` to every
/// response. Each run is wrapped in a `beginBackgroundTask` so it can finish
/// after the app moves to the background.
final class SensorStreamUploader {

    static let shared = SensorStreamUploader()

    /// The most frames one run uploads.
    static let maxFramesPerRun = 20

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        return URLSession(configuration: configuration)
    }()
    private let stateLock = NSLock()
    private var isUploading = false
    private var consecutiveFailures = 0
    private var nextAttempt = Date.distantPast
    private var currentTask: URLSessionTask?

    /// Uploads pending frames, oldest first, and then calls `completion`.
    func uploadPending(participantID: String, completion: @escaping () -> Void) {
        stateLock.lock()
        guard !isUploading, Date() >= nextAttempt else {
            stateLock.unlock()
            return completion()
        }
        isUploading = true
        stateLock.unlock()

        let store: FrameStore
        do {
            store = FrameStore(root: try FrameStore.defaultRoot())
        } catch {
            return finish(completion)
        }
        // Seal frames that an earlier process left open, even when no accelerometer
        // tier is configured now. This runs once per process, before any recorder appends.
        do {
            try store.recoverOpenFramesOncePerProcess()
        } catch {
            printToFile("sensor-stream recovery failed: \(error)")
        }
        let frames = Array(store.sealedFrames().prefix(Self.maxFramesPerRun))
        guard !frames.isEmpty else { return finish(completion) }

        var backgroundTask = UIBackgroundTaskIdentifier.invalid
        let endBackgroundTask = {
            if backgroundTask != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTask = .invalid
            }
        }
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "SensorStreamUpload") { [weak self] in
            // Out of time: cancel the request. The frame stays on disk for the next run.
            self?.stateLock.lock()
            self?.currentTask?.cancel()
            self?.stateLock.unlock()
        }
        upload(frames[...], store: store, participantID: participantID) { [weak self] in
            endBackgroundTask()
            self?.finish(completion)
        }
    }

    private func finish(_ completion: () -> Void) {
        stateLock.lock()
        isUploading = false
        currentTask = nil
        stateLock.unlock()
        completion()
    }

    private func upload(_ frames: ArraySlice<SealedFrame>, store: FrameStore, participantID: String,
                        done: @escaping () -> Void) {
        guard let frame = frames.first else { return done() }
        let next = { self.upload(frames.dropFirst(), store: store, participantID: participantID, done: done) }

        guard frame.metadata.byteLength <= UploadPolicy.maxFrameBytes else {
            // The server would answer 413, which is never retried.
            try? store.quarantine(frame)
            return next()
        }
        let bodyURL = FileManager.default.temporaryDirectory.appendingPathComponent("sensor-stream-\(frame.id).multipart")
        let request: URLRequest
        do {
            let body = try MultipartBodyWriter.write(metadata: frame.metadata, frame: try store.data(for: frame), to: bodyURL)
            request = try makeRequest(participantID: participantID, contentType: body.contentType)
        } catch {
            printToFile("sensor-stream body failed: \(error)")
            try? FileManager.default.removeItem(at: bodyURL)
            return done()
        }

        let task = session.uploadTask(with: request, fromFile: bodyURL) { [weak self] _, response, error in
            try? FileManager.default.removeItem(at: bodyURL)
            guard let self = self else { return done() }
            let statusCode = error == nil ? (response as? HTTPURLResponse)?.statusCode : nil
            switch UploadPolicy.action(forStatusCode: statusCode) {
            case .delete:
                try? store.delete(frame)
                self.recordSuccess()
                next()
            case .quarantine:
                printToFile("sensor-stream frame \(frame.id) quarantined after HTTP \(statusCode ?? 0)")
                try? store.quarantine(frame)
                next()
            case .retryAfterAuthRefresh:
                if statusCode == 401 {
                    self.refreshToken()
                }
                done()
            case .retryWithBackoff:
                self.recordFailure()
                done()
            }
        }
        stateLock.lock()
        currentTask = task
        stateLock.unlock()
        task.resume()
    }

    private func makeRequest(participantID: String, contentType: String) throws -> URLRequest {
        let endpoint = String(format: Endpoint.sensorStream.rawValue, participantID)
        guard let url = URL(string: LampURL.baseURLString + endpoint) else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethodType.post.getTypeString()
        // The same Authorization header as `sensor_event` uploads.
        let headers = RequestData(endpoint: endpoint, requestTye: .post, headers: nil).getRequestHeaders()
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        return request
    }

    private func recordSuccess() {
        stateLock.lock()
        consecutiveFailures = 0
        nextAttempt = .distantPast
        stateLock.unlock()
    }

    private func recordFailure() {
        stateLock.lock()
        consecutiveFailures += 1
        nextAttempt = Date().addingTimeInterval(UploadPolicy.backoffDelay(afterFailures: consecutiveFailures))
        stateLock.unlock()
    }

    private func refreshToken() {
        guard let baseURL = URL(string: LampURL.baseURLString) else { return }
        let session = self.session
        Task {
            await TokenManager.shared.refreshAccessToken(baseURL: baseURL, session: session) { _ in }
        }
    }
}

/// Runs one `SensorStreamUploader` pass inside the background services queue.
final class SensorStreamUploadOperation: AsyncOperation {
    let participantID: String

    init(participantID: String) {
        self.participantID = participantID
    }

    override func main() {
        super.main()
        guard !isCancelled else {
            state = .finished
            return
        }
        SensorStreamUploader.shared.uploadPending(participantID: participantID) { [weak self] in
            self?.state = .finished
        }
    }
}

/// Files that the sensor-stream collectors keep on disk.
enum SensorStreamFiles {
    /// Deletes `Documents/SensorStream` (open, sealed, and quarantined frames).
    static func clearAll() {
        guard let root = try? FrameStore.defaultRoot() else { return }
        try? FrameStore(root: root).removeAll()
    }
}
#endif
