//
//  SpeechTranscriberUseCase.swift
//  CashlyKit
//
//  Live speech-to-text contract. Production impl wraps the iOS
//  Speech framework; in-memory impl yields a canned phrase so
//  feature tests can exercise the dictation pipeline without a
//  microphone or permission grant.
//
//  All implementations expose a long-running AsyncStream of partial
//  transcriptions so the caller can show interim results in the UI
//  before the user stops speaking.
//

import Foundation

public enum SpeechAuthorization: Sendable, Equatable {
    case authorized
    case denied
    case restricted
    case notDetermined
    case unavailable
}

public struct SpeechTranscript: Sendable, Equatable {
    public let text: String
    /// `true` when the speech engine considers the segment final.
    /// UI keeps showing partial results until this flips.
    public let isFinal: Bool

    public init(text: String, isFinal: Bool) {
        self.text = text
        self.isFinal = isFinal
    }
}

public protocol SpeechTranscriberUseCase: Sendable {
    /// Current authorization snapshot. Polled before the UI shows
    /// the mic button.
    func authorizationStatus() async -> SpeechAuthorization
    /// Prompts the user for both Speech recognition + microphone
    /// permissions. Returns the resulting authorization status.
    func requestAuthorization() async -> SpeechAuthorization
    /// Begins a recording session. The returned stream emits one
    /// `SpeechTranscript` per partial result; the consumer stops
    /// the session by cancelling iteration.
    func startTranscription() async throws -> AsyncStream<SpeechTranscript>
    /// Hint to stop the in-flight session early. Caller may also
    /// just stop iterating the stream.
    func stopTranscription() async
}
