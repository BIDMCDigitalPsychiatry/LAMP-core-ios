//
//  SwiftUIWebView.swift
//  SpeechToTextWebView
//
//  Powered by Zco Engineering Dept. on 19/11/24.
//

import Foundation
import AVFoundation
import Speech
import SwiftUI

/// A helper for transcribing speech to text using SFSpeechRecognizer and AVAudioEngine.
actor SpeechRecognizer: ObservableObject {
    enum RecognizerError: Error, LocalizedError {
        case nilRecognizer
        case notAuthorizedToRecognize
        case notPermittedToRecord
        case recognizerIsUnavailable
        
        var errorDescription: String? {
            switch self {
            case .nilRecognizer: return "Could not initialize the speech recognizer.".localized
            case .notAuthorizedToRecognize: return "You are not authorized to recognize the speech.".localized
            case .notPermittedToRecord: return "You are not authorized to record the audio.".localized
            case .recognizerIsUnavailable: return "Recognizer is not available.".localized
            }
        }
        var errorDescriptionForAlert: String? {
            switch self {
            case .nilRecognizer: return errorDescription
            case .notAuthorizedToRecognize: return "You are not authorized to recognize the speech. Enable permission to recognize speech in App Settings to continue.".localized
            case .notPermittedToRecord: return "You are not authorized to record the audio. Enable permission to record audio in App Settings to continue.".localized
            case .recognizerIsUnavailable: return errorDescription
            }
        }
    }
    
    @MainActor var transcript: String = ""
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    
    func checkReconizerCreated() throws {
        guard recognizer != nil else {
            throw RecognizerError.nilRecognizer
        }
        return
    }
    /**
     Initializes a new speech recognizer. If this is the first time you've used the class, it
     requests access to the speech recognizer and the microphone.
     */
    init() {
        recognizer = SFSpeechRecognizer()
    }
    
    func getPermissions() async throws {
        guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
            throw RecognizerError.notAuthorizedToRecognize
        }
//        guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
//            throw RecognizerError.notPermittedToRecord
//        }
    }
    /**
     Begin transcribing audio.
     
     Creates a `SFSpeechRecognitionTask` that transcribes speech to text until you call `stopTranscribing()`.
     The resulting transcription is continuously written to the published `transcript` property.
     */
    func transcribe() throws {

        guard let recognizer, recognizer.isAvailable else {
            throw RecognizerError.recognizerIsUnavailable
        }
        
        do {
            let (audioEngine, request) = try Self.prepareEngine()
            self.audioEngine = audioEngine
            self.request = request
            self.task = recognizer.recognitionTask(with: request, resultHandler: { [weak self] result, error in
                self?.recognitionHandler(audioEngine: audioEngine, result: result, error: error)
            })
        } catch {
            self.reset()
            throw error
        }
    }
    
    /// Reset the speech recognizer.
    func reset() {
        transcribe("")
        task?.cancel()
        audioEngine?.stop()
        audioEngine = nil
        request = nil
        task = nil
    }
    
    private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request)
    }
    
    nonisolated private func recognitionHandler(audioEngine: AVAudioEngine, result: SFSpeechRecognitionResult?, error: Error?) {
        let receivedFinalResult = result?.isFinal ?? false
        let receivedError = error != nil
        
        if receivedFinalResult || receivedError {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        if let result {
            transcribe(result.bestTranscription.formattedString)
        }
    }
    
    
    nonisolated private func transcribe(_ message: String) {
        Task { @MainActor in
            transcript = message
        }
    }
}

extension SFSpeechRecognizer {
    static func hasAuthorizationToRecognize() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}

extension AVAudioSession {
    func hasPermissionToRecord() async -> Bool {
        await withCheckedContinuation { continuation in
            
            requestRecordPermission { authorized in
                continuation.resume(returning: authorized)
            }
            
        }
    }
}
