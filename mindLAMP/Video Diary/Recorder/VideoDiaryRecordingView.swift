// mindLAMP

import SwiftUI
import AVFoundation
import Combine
import UIKit

struct VideoDiaryRecordingView: View {
    let videoHelper: VideoDiaryHelper
    /// Activity name shown centered in the top bar (from web `activityName`). Hidden when nil or empty.
    var activityTitle: String? = nil
    /// Called when the user taps Submit; the owner should dismiss this UI and start a background upload. When `nil`, Submit is hidden after recording.
    var onSubmitRecording: ((URL) -> Void)? = nil
    /// Called when the user closes the recorder from the top bar; the owner should dismiss this UI (e.g. modal hosting controller).
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var environmentDismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var previewReady = false
    /// System alert for camera preview failures (same presentation as Leave Activity).
    @State private var showRecorderBlockingErrorAlert = false
    @State private var recorderBlockingErrorTitle = ""
    @State private var recorderBlockingErrorMessage = ""
    @State private var recorderBlockingErrorShowsSettings = false
    /// True while starting a recording (before capture actually begins).
    @State private var isStartingRecording = false
    /// True after capture has started until the file is finalized.
    @State private var isRecordingActive = false
    /// Latest finished clip; non-nil shows Submit (when upload configuration exists) until upload succeeds.
    @State private var pendingSubmitURL: URL?
    /// Set to true once Submit is tapped so dismissal does not delete the clip before enqueue stages it.
    @State private var didSubmitRecording = false
    /// After at least one successful recording, the primary control title becomes "Record Again".
    @State private var hasFinishedRecordingAtLeastOnce = false
    /// Elapsed time for the current clip (0 when idle; auto-stop uses maximum duration while recording).
    @State private var recordingElapsed: TimeInterval = 0
    /// Bumped whenever the duration timer is invalidated so in-flight Combine callbacks cannot overwrite `recordingElapsed` after reset (e.g. app background).
    @State private var recordingTimerGeneration = 0
    @State private var durationTimerCancellable: AnyCancellable?
    @State private var showLeaveActivityAlert = false
    @State private var leaveActivityAlertMessage = ""
    /// True while stopping recording because the app moved to background — completion discards the partial file instead of offering Submit.
    @State private var abortRecordingDueToBackground = false

    private enum LeaveActivityCopy {
        static let recordingInProgress = "Video recording is in progress. If you leave now, the recorded data might be lost."
        static let recordingNotSubmitted = "You have a recording that hasn't been submitted. If you leave now, the recorded data might be lost."
    }

    private var recordingProgressFraction: Double {
        let maxD = videoHelper.maximumDuration
        guard maxD > 0 else { return 0 }
        return min(1, recordingElapsed / maxD)
    }

    private var elapsedOverMaximumLabel: String {
        let maxD = videoHelper.maximumDuration
        return "\(formatRecordingLength(recordingElapsed)) / \(formatRecordingLength(maxD))"
    }

    private var durationAccessibilityLabel: String {
        let elapsed = formatRecordingLength(recordingElapsed)
        let maxStr = formatRecordingLength(videoHelper.maximumDuration)
        if isRecordingActive {
            return "Recording \(elapsed) of \(maxStr)"
        }
        return "Maximum recording length \(maxStr), elapsed \(elapsed)"
    }

    private var recordButtonRed: Color {
        Color(red: 0.89, green: 0.17, blue: 0.22)
    }

    private var submitButtonBlue: Color {
        Color(red: 0.18, green: 0.42, blue: 0.92)
    }

    /// Submit recording pill — text and outline (#7599FF).
    private var submitRecordingButtonColor: Color {
        Color(red: 117 / 255, green: 153 / 255, blue: 255 / 255)
    }

    /// Same width for Submit and record control; fits longest title + icon without shrinking when the title changes.
    private let primaryActionButtonWidth: CGFloat = 232
    /// Shared fixed height so Submit and record pills match (fits 26pt icon + headline).
    private let primaryActionButtonHeight: CGFloat = 48

    private var primaryRecordButtonTitle: String {
        if isRecordingActive { return "Stop Recording" }
        if hasFinishedRecordingAtLeastOnce { return "Record Again" }
        return "Start Recording"
    }

    var body: some View {
        ZStack {
            CameraPreviewView(session: videoHelper.captureSession)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    ThinRecordingProgressBar(progress: recordingProgressFraction)
                    Text(elapsedOverMaximumLabel)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.55), radius: 3, x: 0, y: 1)
                        .accessibilityLabel(durationAccessibilityLabel)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                Spacer(minLength: 0)
                VStack(spacing: 12) {
                    if pendingSubmitURL != nil, onSubmitRecording != nil, !isRecordingActive {
                        Button {
                            guard let url = pendingSubmitURL else { return }
                            didSubmitRecording = true
                            recordingElapsed = 0
                            onSubmitRecording?(url)
                        } label: {
                            Text("Upload and Submit")
                                .font(.headline.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .multilineTextAlignment(.center)
                                .frame(width: primaryActionButtonWidth, height: primaryActionButtonHeight)
                        }
                        .buttonStyle(
                            SubmitRecordingButtonStyle(accent: submitRecordingButtonColor)
                        )
                        .accessibilityLabel("Upload and submit recording")
                    }

                    Button {
                        if isRecordingActive {
                            videoHelper.stopRecording()
                        } else {
                            guard previewReady, !isStartingRecording else { return }
                            recordingElapsed = 0
                            if let staleURL = pendingSubmitURL {
                                removeLocalVideoIfPresent(staleURL)
                                pendingSubmitURL = nil
                            }
                            isStartingRecording = true
                            videoHelper.startRecording(
                                onRecordingStarted: {
                                    if abortRecordingDueToBackground {
                                        videoHelper.stopRecording()
                                        return
                                    }
                                    isStartingRecording = false
                                    isRecordingActive = true
                                    startRecordingDurationTimer()
                                },
                                completion: { result in
                                    isStartingRecording = false
                                    isRecordingActive = false
                                    if abortRecordingDueToBackground {
                                        abortRecordingDueToBackground = false
                                        stopRecordingDurationTimer(resetElapsed: true)
                                        if case let .success(url) = result {
                                            removeLocalVideoIfPresent(url)
                                        }
                                        return
                                    }
                                    switch result {
                                    case .success(let url):
                                        stopRecordingDurationTimer()
                                        didSubmitRecording = false
                                        if let staleURL = pendingSubmitURL, staleURL.path != url.path {
                                            removeLocalVideoIfPresent(staleURL)
                                        }
                                        pendingSubmitURL = url
                                        hasFinishedRecordingAtLeastOnce = true
                                    case .failure:
                                        // e.g. session interrupted before `didEnterBackground` / scene `.background` runs
                                        stopRecordingDurationTimer(resetElapsed: true)
                                    }
                                }
                            )
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Spacer(minLength: 0)
                            Group {
                                if isStartingRecording {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(1.05)
                                } else if isRecordingActive {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .frame(width: 22, height: 22)
                                } else {
                                    Circle()
                                        .frame(width: 18, height: 18)
                                }
                            }
                            .frame(width: 26, height: 26)

                            Text(primaryRecordButtonTitle)
                                .font(.headline.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.86)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .frame(width: primaryActionButtonWidth, height: primaryActionButtonHeight)
                    }
                    .buttonStyle(
                        PrimaryRecordButtonStyle(accent: recordButtonRed, isRecording: isRecordingActive)
                    )
                    .disabled(isStartingRecording || (!previewReady && !isRecordingActive))
                    .opacity((!previewReady && !isRecordingActive) ? 0.45 : 1)
                    .accessibilityLabel(
                        isRecordingActive ? "Stop recording"
                            : isStartingRecording ? "Starting recording"
                            : hasFinishedRecordingAtLeastOnce ? "Record again"
                            : "Start recording"
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .background(Color.black)
        .safeAreaInset(edge: .top, spacing: 0) {
            ZStack {
                if let title = activityTitle, !title.isEmpty {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 52)
                        .accessibilityAddTraits(.isHeader)
                }
                HStack {
                    Button {
                        handleBackButtonTap()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(submitButtonBlue)
        }
        .alert(
            recorderBlockingErrorTitle,
            isPresented: $showRecorderBlockingErrorAlert,
            actions: {
                if recorderBlockingErrorShowsSettings {
                    Button("OK") {
                        openAppSettingsForPermissions()
                    }
                }
                Button("CANCEL", role: .cancel) {
                    DispatchQueue.main.async {
                        dismissRecordingView()
                    }
                }
            },
            message: {
                Text(recorderBlockingErrorMessage)
            }
        )
        .alert(
            "Leave Activity?",
            isPresented: $showLeaveActivityAlert,
            actions: {
                Button("Stay", role: .cancel) {
                    showLeaveActivityAlert = false
                }
                Button("Leave", role: .destructive) {
                    // Defer past alert teardown so UIKit + hosting controller don’t fight the same transition frame.
                    DispatchQueue.main.async {
                        dismissRecordingView()
                    }
                }
            },
            message: {
                Text(leaveActivityAlertMessage)
            }
        )
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                videoHelper.ensureCaptureSessionRunning()
                reconcileRecordingElapsedAfterForeground()
            case .background:
                handleRecordingInterruptedByBackground()
            default:
                break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            handleRecordingInterruptedByBackground()
        }
        .onAppear {
            videoHelper.prepareCameraPreview { result in
                switch result {
                case .success:
                    previewReady = true
                case .failure(let error):
                    let permissionDenied = (error as? VideoDiaryRecorderError) == .permissionDenied
                    recorderBlockingErrorTitle = permissionDenied ? "Permission Required" : "Error"
                    recorderBlockingErrorMessage = "Camera and microphone access are required to record a video diary. Please grant both permissions to continue."
                    recorderBlockingErrorShowsSettings = permissionDenied
                    showRecorderBlockingErrorAlert = true
                }
            }
        }
        .onDisappear {
            stopRecordingDurationTimer()
            videoHelper.stopCameraPreview()
            if !didSubmitRecording, let staleURL = pendingSubmitURL {
                removeLocalVideoIfPresent(staleURL)
                pendingSubmitURL = nil
            }
        }
    }

    /// If we are idle with no clip waiting to submit, force the duration label back to `0:00` (fixes stuck UI when iOS ends the take before our scene reports `.background`).
    private func reconcileRecordingElapsedAfterForeground() {
        guard !isRecordingActive, !isStartingRecording, pendingSubmitURL == nil else { return }
        stopRecordingDurationTimer(resetElapsed: true)
    }

    private func openAppSettingsForPermissions() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    /// `AVCaptureMovieFileOutput` cannot pause/resume a single file. When the user leaves the app we stop the take, delete any partial file, and reset controls (brief `.inactive` from screenshots is ignored).
    private func handleRecordingInterruptedByBackground() {
        guard isRecordingActive || isStartingRecording else { return }
        abortRecordingDueToBackground = true
        stopRecordingDurationTimer(resetElapsed: true)
        isRecordingActive = false
        isStartingRecording = false
        videoHelper.stopRecording()
    }

    private func handleBackButtonTap() {
        if isRecordingActive || isStartingRecording {
            leaveActivityAlertMessage = LeaveActivityCopy.recordingInProgress
            showLeaveActivityAlert = true
            return
        }
        if pendingSubmitURL != nil, !didSubmitRecording {
            leaveActivityAlertMessage = LeaveActivityCopy.recordingNotSubmitted
            showLeaveActivityAlert = true
            return
        }
        dismissRecordingView()
    }

    private func dismissRecordingView() {
        if isRecordingActive {
            videoHelper.stopRecording()
        }
        stopRecordingDurationTimer()
        if let onDismiss {
            onDismiss()
        } else {
            environmentDismiss()
        }
    }

    private func startRecordingDurationTimer() {
        recordingTimerGeneration += 1
        let generation = recordingTimerGeneration
        durationTimerCancellable?.cancel()
        durationTimerCancellable = nil
        recordingElapsed = 0
        let beganAt = Date()
        let limit = videoHelper.maximumDuration
        durationTimerCancellable = Timer.publish(every: 0.1, tolerance: 0.03, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard generation == recordingTimerGeneration else { return }
                let elapsed = Date().timeIntervalSince(beganAt)
                recordingElapsed = elapsed
                let remaining = max(0, limit - elapsed)
                if remaining <= 0 {
                    stopRecordingDurationTimer()
                    videoHelper.stopRecording()
                }
            }
    }

    /// Stops duration updates. Use `resetElapsed: true` when abandoning a take so the label returns to `0:00 / max`.
    private func stopRecordingDurationTimer(resetElapsed: Bool = false) {
        recordingTimerGeneration += 1
        durationTimerCancellable?.cancel()
        durationTimerCancellable = nil
        if resetElapsed {
            recordingElapsed = 0
        }
    }

    /// Whole seconds elapsed since recording started.
    private func formatRecordingLength(_ t: TimeInterval) -> String {
        let secs = max(0, Int(floor(t)))
        let m = secs / 60
        let s = secs % 60
        return String(format: "%d:%02d", m, s)
    }

    private func removeLocalVideoIfPresent(_ url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            printDebug("[VideoDiaryUpload] failed to remove local temp video \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
}

/// Submit pill: white background + accent text/border at rest, accent background + white text while pressed.
private struct SubmitRecordingButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(pressed ? Color.white : accent)
            .background(Capsule().fill(pressed ? accent : Color.white))
            .overlay(Capsule().stroke(accent, lineWidth: 2))
            .contentShape(Capsule())
            .animation(.easeOut(duration: 0.12), value: pressed)
    }
}

/// Primary record pill: white background + accent text/icon/border at rest; flips to accent background + white content while pressed (Start / Record Again). Stays accent-filled with white content during an active recording.
private struct PrimaryRecordButtonStyle: ButtonStyle {
    let accent: Color
    let isRecording: Bool

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let inverted = isRecording || pressed
        let contentColor = inverted ? Color.white : accent
        let backgroundColor = inverted ? accent : Color.white
        configuration.label
            .foregroundStyle(contentColor)
            .tint(contentColor)
            .background(Capsule().fill(backgroundColor))
            .overlay(Capsule().stroke(accent, lineWidth: isRecording ? 0 : 2))
            .contentShape(Capsule())
            .animation(.easeOut(duration: 0.12), value: inverted)
    }
}

/// Thin horizontal fill for recording progress (0…1).
/// Two-color gradient along the track: calm green → red as recording approaches the limit.
private struct ThinRecordingProgressBar: View {
    var progress: Double

    private static let phaseStart = Color(red: 0.28, green: 0.76, blue: 0.52)
    private static let phaseEnd = Color(red: 0.95, green: 0.30, blue: 0.34)

    private static var trackGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: phaseStart, location: 0),
                .init(color: phaseEnd, location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        GeometryReader { geo in
            let totalW = geo.size.width
            let h = geo.size.height
            let fillW = totalW * min(1, max(0, progress))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.22))
                Self.trackGradient
                    .frame(width: totalW, height: h)
                    .mask(alignment: .leading) {
                        Capsule()
                            .frame(width: max(0, fillW))
                            .frame(height: h)
                    }
            }
        }
        .frame(height: 5)
        .accessibilityHidden(true)
    }
}

private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewContainerView {
        let v = PreviewContainerView()
        v.previewLayer.session = session
        v.previewLayer.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
        uiView.applyFrontCameraPreviewMirroring()
    }
}

private final class PreviewContainerView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        applyFrontCameraPreviewMirroring()
    }

    /// Front-camera preview matches the mirror people expect when framing a selfie.
    fileprivate func applyFrontCameraPreviewMirroring() {
        guard let connection = previewLayer.connection else { return }
        connection.automaticallyAdjustsVideoMirroring = false
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = true
        }
    }
}

#Preview {
    let configuration = VideoDiary.RecordingConfiguration(
        maximumDuration: 60,
        resolution: .hd1080p,
        bitratePerSecond: 6_000_000,
        frameRate: 30,
        captureMetadata: true
    )
    let helper = VideoDiaryHelper(configuration: configuration)
    VideoDiaryRecordingView(videoHelper: helper, onSubmitRecording: { _ in })
}
