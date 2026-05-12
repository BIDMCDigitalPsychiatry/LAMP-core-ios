// mindLAMP

import AVFoundation

enum VideoDiaryRecorderError: Error, LocalizedError {
    case permissionDenied
    case noVideoDevice
    case cannotAddOutput
    case alreadyRecording

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera and microphone access are needed to record video."
        case .noVideoDevice:
            return "No camera is available on this device."
        case .cannotAddOutput:
            return "Could not set up video recording."
        case .alreadyRecording:
            return "A recording is already in progress."
        }
    }
}

/// Configures an `AVCaptureSession` and records video (and audio when allowed) via `AVCaptureMovieFileOutput`.
final class VideoDiaryAVRecorder: NSObject {

    private let configuration: VideoDiary.RecordingConfiguration
    private let session = AVCaptureSession()

    /// Same session used by `AVCaptureVideoPreviewLayer` (read on the main thread; configuration stays on `sessionQueue`).
    var captureSession: AVCaptureSession { session }
    private let movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "org.digital.lamp.mindlamp.videodiary.recorder")

    private var isSessionConfigured = false
    private var sessionNotificationsRegistered = false
    private var recordingCompletion: ((Swift.Result<URL, Error>) -> Void)?
    private var recordingDidStartHandler: (() -> Void)?

    init(configuration: VideoDiary.RecordingConfiguration) {
        self.configuration = configuration
        super.init()
        movieOutput.movieFragmentInterval = .invalid
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func startRecording(
        onRecordingStarted: (() -> Void)? = nil,
        completion: @escaping (Swift.Result<URL, Error>) -> Void
    ) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.movieOutput.isRecording else {
                DispatchQueue.main.async { completion(.failure(VideoDiaryRecorderError.alreadyRecording)) }
                return
            }
            self.ensurePermissions { [weak self] granted in
                guard let self else { return }
                self.sessionQueue.async {
                    guard granted else {
                        DispatchQueue.main.async { completion(.failure(VideoDiaryRecorderError.permissionDenied)) }
                        return
                    }
                    do {
                        try self.configureSessionIfNeeded()
                    } catch {
                        DispatchQueue.main.async { completion(.failure(error)) }
                        return
                    }
                    if !self.session.isRunning {
                        self.session.startRunning()
                    }
                    let url = FileManager.default.temporaryDirectory
                        .appendingPathComponent("VideoDiary-\(UUID().uuidString).mov")
                    self.recordingCompletion = completion
                    self.recordingDidStartHandler = onRecordingStarted
                    self.movieOutput.startRecording(to: url, recordingDelegate: self)
                }
            }
        }
    }

    func stopRecording() {
        sessionQueue.async { [weak self] in
            guard let self, self.movieOutput.isRecording else { return }
            self.movieOutput.stopRecording()
        }
    }

    /// Ensures permissions, configures inputs/output, and starts the session so live preview can attach.
    func prepareForPreview(completion: @escaping (Swift.Result<Void, Error>) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.ensurePermissions { [weak self] granted in
                guard let self else { return }
                self.sessionQueue.async {
                    guard granted else {
                        DispatchQueue.main.async { completion(.failure(VideoDiaryRecorderError.permissionDenied)) }
                        return
                    }
                    do {
                        try self.configureSessionIfNeeded()
                    } catch {
                        DispatchQueue.main.async { completion(.failure(error)) }
                        return
                    }
                    if !self.session.isRunning {
                        self.session.startRunning()
                    }
                    DispatchQueue.main.async { completion(.success(())) }
                }
            }
        }
    }

    /// Stops the capture session when not recording (e.g. leaving the preview screen).
    func stopPreviewSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.movieOutput.isRecording, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    /// Restarts the capture session if the system stopped it (e.g. screenshot overlay, phone call, brief inactive → active).
    func ensureCaptureSessionRunning() {
        sessionQueue.async { [weak self] in
            self?.startSessionIfNeeded()
        }
    }

    private func startSessionIfNeeded() {
        guard isSessionConfigured else { return }
        if !session.isRunning {
            session.startRunning()
        }
    }

    private func registerSessionNotificationsIfNeeded() {
        guard !sessionNotificationsRegistered else { return }
        sessionNotificationsRegistered = true
        let nc = NotificationCenter.default
        nc.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded(_:)),
            name: AVCaptureSession.interruptionEndedNotification,
            object: session
        )
        nc.addObserver(
            self,
            selector: #selector(sessionRuntimeError(_:)),
            name: AVCaptureSession.runtimeErrorNotification,
            object: session
        )
    }

    @objc private func sessionInterruptionEnded(_ notification: Notification) {
        sessionQueue.async { [weak self] in
            self?.startSessionIfNeeded()
        }
    }

    @objc private func sessionRuntimeError(_ notification: Notification) {
        sessionQueue.async { [weak self] in
            self?.startSessionIfNeeded()
        }
    }

    private func ensurePermissions(completion: @escaping (Bool) -> Void) {
        requestVideoAccess { videoOK in
            guard videoOK else {
                completion(false)
                return
            }
            self.requestAudioAccess { _ in
                completion(true)
            }
        }
    }

    private func requestVideoAccess(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
        default:
            completion(false)
        }
    }

    private func requestAudioAccess(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: completion)
        default:
            completion(false)
        }
    }

    private func configureSessionIfNeeded() throws {
        guard !isSessionConfigured else { return }

        session.beginConfiguration()

        let preset = configuration.resolution.captureSessionPreset
        if session.canSetSessionPreset(preset) {
            session.sessionPreset = preset
        } else {
            session.sessionPreset = .high
        }

        guard
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
            session.canAddInput(videoInput)
        else {
            session.commitConfiguration()
            throw VideoDiaryRecorderError.noVideoDevice
        }
        session.addInput(videoInput)

        try configureFrameRate(for: videoDevice)

        if
            let audioDevice = AVCaptureDevice.default(for: .audio),
            let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
            session.canAddInput(audioInput)
        {
            session.addInput(audioInput)
        }

        guard session.canAddOutput(movieOutput) else {
            session.commitConfiguration()
            throw VideoDiaryRecorderError.cannotAddOutput
        }
        session.addOutput(movieOutput)

        if configuration.captureMetadata {
            movieOutput.metadata = Self.makeRecordingMetadataItems()
        } else {
            movieOutput.metadata = []
        }

        if let connection = movieOutput.connection(with: .video),
           movieOutput.availableVideoCodecTypes.contains(.h264) {
            let compression: [String: Any] = [
                AVVideoAverageBitRateKey: configuration.bitratePerSecond,
                AVVideoMaxKeyFrameIntervalKey: max(1, configuration.frameRate * 2)
            ]
            let outputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoCompressionPropertiesKey: compression
            ]
            movieOutput.setOutputSettings(outputSettings, for: connection)
        }

        session.commitConfiguration()
        isSessionConfigured = true
        registerSessionNotificationsIfNeeded()
    }

    private func configureFrameRate(for device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        let target = Double(configuration.frameRate)
        let ranges = device.activeFormat.videoSupportedFrameRateRanges
        let fps: Double
        if let r = ranges.first(where: { target >= $0.minFrameRate && target <= $0.maxFrameRate }) {
            fps = target
        } else if let widest = ranges.max(by: { $0.maxFrameRate < $1.maxFrameRate }) {
            fps = min(max(target, widest.minFrameRate), widest.maxFrameRate)
        } else {
            return
        }

        let duration = CMTime(seconds: 1.0 / fps, preferredTimescale: 600)
        device.activeVideoMinFrameDuration = duration
        device.activeVideoMaxFrameDuration = duration
    }

    private static func makeRecordingMetadataItems() -> [AVMetadataItem] {
        let software = AVMutableMetadataItem()
        software.identifier = .commonIdentifierSoftware
        software.value = "VideoRecordingTestApp" as NSString

        let description = AVMutableMetadataItem()
        description.identifier = .commonIdentifierDescription
        description.value = "VideoRecordingTestApp capture" as NSString

        return [software, description]
    }
}

extension VideoDiaryAVRecorder: AVCaptureFileOutputRecordingDelegate {

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            let handler = self.recordingDidStartHandler
            self.recordingDidStartHandler = nil
            DispatchQueue.main.async { handler?() }
        }
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.recordingDidStartHandler = nil
            let finish = self.recordingCompletion
            self.recordingCompletion = nil
            if let error {
                DispatchQueue.main.async { finish?(.failure(error)) }
            } else {
                DispatchQueue.main.async { finish?(.success(outputFileURL)) }
            }
        }
    }
}
