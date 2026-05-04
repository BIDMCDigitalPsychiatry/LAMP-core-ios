// mindLAMP

import AVFoundation
import Foundation

final class VideoDiaryHelper {

    private let configuration: VideoDiary.RecordingConfiguration

    private let recorder: VideoDiaryAVRecorder

    init(configuration: VideoDiary.RecordingConfiguration) {
        self.configuration = configuration
        self.recorder = VideoDiaryAVRecorder(configuration: configuration)
    }

    var captureSession: AVCaptureSession {
        recorder.captureSession
    }
    
    var maximumDuration: TimeInterval {
        configuration.maximumDuration
    }

    var recordingConfiguration: VideoDiary.RecordingConfiguration {
        configuration
    }

    func prepareCameraPreview(completion: @escaping (Swift.Result<Void, Error>) -> Void) {
        recorder.prepareForPreview(completion: completion)
    }

    func stopCameraPreview() {
        recorder.stopPreviewSession()
    }

    /// Begins writing a movie file. Call `stopRecording()` when finished. `completion` runs after the file is finalized.
    func startRecording(
        onRecordingStarted: (() -> Void)? = nil,
        completion: ((Swift.Result<URL, Error>) -> Void)? = nil
    ) {
        recorder.startRecording(onRecordingStarted: onRecordingStarted) { result in
            completion?(result)
            if case let .success(url) = result {
                print("VideoDiaryHelper: recording finished at \(url.path)")
            } else if case let .failure(error) = result {
                print("VideoDiaryHelper: recording failed — \(error.localizedDescription)")
            }
        }
    }

    func stopRecording() {
        recorder.stopRecording()
    }
}


enum VideoRecordingResolution: String, CaseIterable, Sendable, Codable {
    case hd720p
    case hd1080p
    case uhd4K

    var captureSessionPreset: AVCaptureSession.Preset {
        switch self {
        case .hd720p: return .hd1280x720
        case .hd1080p: return .hd1920x1080
        case .uhd4K: return .hd4K3840x2160
        }
    }
}

enum VideoDiary {
    /// Provided by the owner (e.g. web message for `beginVideoDiary`) and passed into `VideoDiaryHelper`.
    struct RecordingConfiguration: Equatable, Sendable, Codable {
        /// Maximum clip length in seconds (UI countdown and auto-stop).
        var maximumDuration: TimeInterval
        /// Session preset controlling captured video dimensions (within device capability).
        var resolution: VideoRecordingResolution
        /// Target average video bitrate in bits per second (passed to the encoder when supported).
        var bitratePerSecond: Int
        /// Target frames per second (clamped to the active format’s supported range).
        var frameRate: Int
        /// When true, attaches basic file metadata (e.g. software / description) to the movie output.
        var captureMetadata: Bool
    }

    /// Backend multipart upload (initiate → S3 parts → complete). Build `VideoMultipartUploadService` separately when uploading after the recorder dismisses.
    struct VideoUploadConfiguration: Equatable, Sendable, Codable {
        /// e.g. `URL(string: "https://api.example.com")!`
        var apiBaseURL: URL
        var participantId: String
        var activityId: String
        /// Optional `Authorization` header value (e.g. `"Bearer …"`).
        var authorizationHeaderValue: String?
    }
}

extension VideoRecordingResolution {
    var pixelDimensions: (width: Int, height: Int) {
        switch self {
        case .hd720p: return (1280, 720)
        case .hd1080p: return (1920, 1080)
        case .uhd4K: return (3840, 2160)
        }
    }
}

// MARK: - Web / WKScriptMessage body parsing (beginVideoDiary)

enum VideoDiaryMessageParsing {
    static func string(from any: Any?) -> String? {
        if let s = any as? String { return s.isEmpty ? nil : s }
        if let n = any as? NSNumber { return n.stringValue }
        return nil
    }

    static func int(from any: Any?) -> Int? {
        if let i = any as? Int { return i }
        if let n = any as? NSNumber { return n.intValue }
        return nil
    }

    static func double(from any: Any?) -> Double? {
        if let d = any as? Double { return d }
        if let n = any as? NSNumber { return n.doubleValue }
        if let s = any as? String, let d = Double(s) { return d }
        return nil
    }

    static func bool(from any: Any?) -> Bool? {
        if let b = any as? Bool { return b }
        if let i = int(from: any) { return i != 0 }
        if let s = string(from: any) {
            switch s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "1", "true", "yes": return true
            case "0", "false", "no": return false
            default: return nil
            }
        }
        return nil
    }

    static func nonNegativeTimeIntervalSeconds(from any: Any?) -> TimeInterval? {
        if let t = double(from: any) { return t >= 0 ? t : nil }
        if let i = int(from: any) { return i >= 0 ? TimeInterval(i) : nil }
        return nil
    }

    static func videoResolution(from any: Any?) -> VideoRecordingResolution? {
        if let i = int(from: any) {
            switch i {
            case 720: return .hd720p
            case 1080: return .hd1080p
            case 2160, 3840: return .uhd4K
            default: break
            }
        }
        guard let s = string(from: any) else { return nil }
        let key = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch key {
        case "720p", "hd720", "1280x720", "720": return .hd720p
        case "1080p", "1080", "1920x1080": return .hd1080p
        case "4k", "2160p", "3840x2160", "uhd", "uhd4k": return .uhd4K
        default:
            return VideoRecordingResolution(rawValue: key)
        }
    }
}

extension VideoDiary.RecordingConfiguration {
    /// Expects `settings` from the dashboard / webview: `frameRate`, `maxBitrateMbps`, `maxDurationInSec`, `metadataCapture`, `resolution`.
    init?(messageBody: [String: Any]) {
        guard let settings = messageBody["settings"] as? [String: Any] else { return nil }
        guard let maxDuration = VideoDiaryMessageParsing.nonNegativeTimeIntervalSeconds(from: settings["maxDurationInSec"]),
              let resolution = VideoDiaryMessageParsing.videoResolution(from: settings["resolution"]) else {
            return nil
        }
        let frameRate = VideoDiaryMessageParsing.int(from: settings["frameRate"]) ?? 30
        let mbps = VideoDiaryMessageParsing.double(from: settings["maxBitrateMbps"]) ?? 2
        let bitratePerSecond = max(1, Int(mbps * 1_000_000))
        let captureMetadata = VideoDiaryMessageParsing.bool(from: settings["metadataCapture"]) ?? false
        self.init(
            maximumDuration: maxDuration,
            resolution: resolution,
            bitratePerSecond: bitratePerSecond,
            frameRate: max(1, frameRate),
            captureMetadata: captureMetadata
        )
    }
}
