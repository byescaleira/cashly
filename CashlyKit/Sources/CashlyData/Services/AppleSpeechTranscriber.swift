//
//  AppleSpeechTranscriber.swift
//  CashlyKit
//
//  Speech.framework + AVAudioEngine wrapper. Streams partial
//  transcriptions back to the caller via an AsyncStream so the UI
//  can show interim text while the user is still speaking.
//
//  Permission flow: callers should `requestAuthorization()` before
//  `startTranscription()`; the method throws when the user denies
//  either Speech recognition or microphone access.
//

import Foundation
import CashlyDomain
#if canImport(Speech)
import Speech
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif

public final class AppleSpeechTranscriber: SpeechTranscriberUseCase, @unchecked Sendable {
    #if canImport(Speech)
    private let recognizer: SFSpeechRecognizer?
    #endif
    #if canImport(AVFoundation)
    private let audioEngine = AVAudioEngine()
    #endif
    #if canImport(Speech)
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    #endif

    public init(locale: Locale = .current) {
        #if canImport(Speech)
        self.recognizer = SFSpeechRecognizer(locale: locale)
        #endif
    }

    public func authorizationStatus() async -> SpeechAuthorization {
        #if canImport(Speech)
        return Self.map(SFSpeechRecognizer.authorizationStatus())
        #else
        return .unavailable
        #endif
    }

    public func requestAuthorization() async -> SpeechAuthorization {
        #if canImport(Speech)
        let speechStatus: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status)
            }
        }
        let speech = Self.map(speechStatus)
        guard speech == .authorized else { return speech }
        #if os(iOS) && canImport(AVFoundation)
        let micGranted: Bool = await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
        return micGranted ? .authorized : .denied
        #else
        return speech
        #endif
        #else
        return .unavailable
        #endif
    }

    public func startTranscription() async throws -> AsyncStream<SpeechTranscript> {
        #if canImport(Speech) && canImport(AVFoundation) && os(iOS)
        guard let recognizer, recognizer.isAvailable else {
            throw NSError(domain: "AppleSpeechTranscriber", code: -1)
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        return AsyncStream { continuation in
            self.task = recognizer.recognitionTask(with: request) { result, error in
                if let result {
                    let transcript = SpeechTranscript(
                        text: result.bestTranscription.formattedString,
                        isFinal: result.isFinal
                    )
                    continuation.yield(transcript)
                    if result.isFinal { continuation.finish() }
                }
                if error != nil { continuation.finish() }
            }
            continuation.onTermination = { @Sendable _ in
                Task { await self.stopTranscription() }
            }
        }
        #else
        throw NSError(domain: "AppleSpeechTranscriber", code: -2)
        #endif
    }

    public func stopTranscription() async {
        #if canImport(Speech) && canImport(AVFoundation) && os(iOS)
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }

    #if canImport(Speech)
    private static func map(_ status: SFSpeechRecognizerAuthorizationStatus) -> SpeechAuthorization {
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .unavailable
        }
    }
    #endif
}
