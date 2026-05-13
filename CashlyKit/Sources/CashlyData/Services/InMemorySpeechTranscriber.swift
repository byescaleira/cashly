//
//  InMemorySpeechTranscriber.swift
//  CashlyKit
//
//  Test stub. Returns a configurable authorization status and
//  yields a canned phrase as a single final transcript, with no
//  microphone access required.
//

import Foundation
import CashlyDomain

public actor InMemorySpeechTranscriber: SpeechTranscriberUseCase {
    private var authorization: SpeechAuthorization
    private var cannedPhrase: String
    public private(set) var stopCount: Int = 0

    public init(
        authorization: SpeechAuthorization = .authorized,
        cannedPhrase: String = "almoço 25 reais"
    ) {
        self.authorization = authorization
        self.cannedPhrase = cannedPhrase
    }

    public func setAuthorization(_ status: SpeechAuthorization) {
        self.authorization = status
    }

    public func setCannedPhrase(_ phrase: String) {
        self.cannedPhrase = phrase
    }

    public func authorizationStatus() async -> SpeechAuthorization {
        authorization
    }

    public func requestAuthorization() async -> SpeechAuthorization {
        authorization
    }

    public func startTranscription() async throws -> AsyncStream<SpeechTranscript> {
        let phrase = cannedPhrase
        return AsyncStream { continuation in
            continuation.yield(SpeechTranscript(text: phrase, isFinal: true))
            continuation.finish()
        }
    }

    public func stopTranscription() async {
        stopCount += 1
    }
}
