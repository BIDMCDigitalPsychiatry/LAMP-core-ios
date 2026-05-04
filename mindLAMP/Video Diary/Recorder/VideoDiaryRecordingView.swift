// mindLAMP

import SwiftUI
import AVFoundation
import Combine
import UIKit

struct VideoDiaryRecordingView: View {
    let videoHelper: VideoDiaryHelper
    /// Called when the user taps Submit; the owner should dismiss this UI and start a background upload. When `nil`, Submit is hidden after recording.
    var onSubmitRecording: ((URL) -> Void)? = nil

    @State private var previewReady = false
    @State private var errorMessage: String?
    /// True while starting a recording (before capture actually begins).
    @State private var isStartingRecording = false
    /// True after capture has started until the file is finalized.
    @State private var isRecordingActive = false
    /// Latest finished clip; non-nil shows Submit (when upload configuration exists) until upload succeeds.
    @State private var pendingSubmitURL: URL?
    /// After at least one successful recording, the primary control title becomes "Record Again".
    @State private var hasFinishedRecordingAtLeastOnce = false
    /// Elapsed time for the current clip (0 when idle; auto-stop uses maximum duration while recording).
    @State private var recordingElapsed: TimeInterval = 0
    @State private var durationTimerCancellable: AnyCancellable?

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

            if let errorText = errorMessage {
                ZStack {
                    Color.black.opacity(0.75)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            errorMessage = nil
                        }

                    VStack(spacing: 20) {
                        Text(errorText)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .font(.body)

                        Button {
                            errorMessage = nil
                        } label: {
                            Text("OK")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.black)
                                .frame(minWidth: 120)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                                .background(Capsule().fill(Color.white))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Dismiss error")
                    }
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                    )
                    .padding(.horizontal, 32)
                }
                .transition(.opacity)
            }

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
                .padding(.top, 10)
                Spacer(minLength: 0)
                VStack(spacing: 12) {
                    if pendingSubmitURL != nil, onSubmitRecording != nil, !isRecordingActive {
                        Button {
                            guard let url = pendingSubmitURL else { return }
                            onSubmitRecording?(url)
                        } label: {
                            Text("Submit")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(submitButtonBlue)
                                .frame(width: primaryActionButtonWidth, height: primaryActionButtonHeight)
                                .background(Capsule().fill(Color.white))
                                .overlay(Capsule().stroke(submitButtonBlue, lineWidth: 2))
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Submit recording")
                    }

                    Button {
                        if isRecordingActive {
                            videoHelper.stopRecording()
                        } else {
                            guard previewReady, !isStartingRecording else { return }
                            isStartingRecording = true
                            videoHelper.startRecording(
                                onRecordingStarted: {
                                    isStartingRecording = false
                                    isRecordingActive = true
                                    startRecordingDurationTimer()
                                },
                                completion: { result in
                                    isStartingRecording = false
                                    isRecordingActive = false
                                    stopRecordingDurationTimer()
                                    if case let .success(url) = result {
                                        pendingSubmitURL = url
                                        hasFinishedRecordingAtLeastOnce = true
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
                                        .tint(recordButtonRed)
                                        .scaleEffect(1.05)
                                } else if isRecordingActive {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(Color.white)
                                        .frame(width: 22, height: 22)
                                } else {
                                    Circle()
                                        .fill(recordButtonRed)
                                        .frame(width: 18, height: 18)
                                }
                            }
                            .frame(width: 26, height: 26)

                            Text(primaryRecordButtonTitle)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(isRecordingActive ? Color.white : recordButtonRed)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.86)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .frame(width: primaryActionButtonWidth, height: primaryActionButtonHeight)
                        .background(Capsule().fill(isRecordingActive ? recordButtonRed : Color.white))
                        .overlay(Capsule().stroke(recordButtonRed, lineWidth: isRecordingActive ? 0 : 2))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
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
        .onAppear {
            videoHelper.prepareCameraPreview { result in
                switch result {
                case .success:
                    previewReady = true
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
        .onDisappear {
            stopRecordingDurationTimer()
            videoHelper.stopCameraPreview()
        }
    }

    private func startRecordingDurationTimer() {
        durationTimerCancellable?.cancel()
        recordingElapsed = 0
        let beganAt = Date()
        let limit = videoHelper.maximumDuration
        durationTimerCancellable = Timer.publish(every: 0.1, tolerance: 0.03, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let elapsed = Date().timeIntervalSince(beganAt)
                recordingElapsed = elapsed
                let remaining = max(0, limit - elapsed)
                if remaining <= 0 {
                    durationTimerCancellable?.cancel()
                    durationTimerCancellable = nil
                    videoHelper.stopRecording()
                }
            }
    }

    private func stopRecordingDurationTimer() {
        durationTimerCancellable?.cancel()
        durationTimerCancellable = nil
        recordingElapsed = 0
    }

    /// Whole seconds elapsed since recording started.
    private func formatRecordingLength(_ t: TimeInterval) -> String {
        let secs = max(0, Int(floor(t)))
        let m = secs / 60
        let s = secs % 60
        return String(format: "%d:%02d", m, s)
    }
}

/// Thin horizontal fill for recording progress (0…1).
/// Gradient along the track: ~0–80% soft blue-green, ~81–90% yellow, ~91–100% soft red.
private struct ThinRecordingProgressBar: View {
    var progress: Double

    private static let comfortable = Color(red: 0.38, green: 0.66, blue: 0.74)
    private static let cautionYellow = Color(red: 0.95, green: 0.78, blue: 0.30)
    private static let softRed = Color(red: 0.90, green: 0.44, blue: 0.46)

    private static var trackGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: comfortable, location: 0),
                .init(color: comfortable, location: 0.78),
                .init(color: comfortable, location: 0.805),
                .init(color: cautionYellow, location: 0.806),
                .init(color: cautionYellow, location: 0.895),
                .init(color: softRed, location: 0.915),
                .init(color: softRed, location: 1.0),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        GeometryReader { geo in
            let totalW = geo.size.width
            let fillW = totalW * min(1, max(0, progress))
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.22))
                Self.trackGradient
                    .frame(width: totalW, height: 3)
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: max(0, fillW))
                    }
            }
        }
        .frame(height: 3)
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
