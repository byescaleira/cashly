//
//  InMemorySpeechTranscriberTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyData

@Suite("InMemorySpeechTranscriber", .tags(.unit, .local))
struct InMemorySpeechTranscriberTests {

    @Test("default authorization is .authorized")
    func defaultAuth() async {
        let svc = InMemorySpeechTranscriber()
        #expect(await svc.authorizationStatus() == .authorized)
    }

    @Test("setAuthorization mutates status")
    func setAuth() async {
        let svc = InMemorySpeechTranscriber()
        await svc.setAuthorization(.denied)
        #expect(await svc.requestAuthorization() == .denied)
    }

    @Test("startTranscription yields a single final transcript")
    func transcription() async throws {
        let svc = InMemorySpeechTranscriber(cannedPhrase: "almoço 25")
        let stream = try await svc.startTranscription()
        var emitted: [SpeechTranscript] = []
        for await transcript in stream { emitted.append(transcript) }
        #expect(emitted.count == 1)
        #expect(emitted.first?.text == "almoço 25")
        #expect(emitted.first?.isFinal == true)
    }

    @Test("stopTranscription bumps the counter")
    func stopCount() async throws {
        let svc = InMemorySpeechTranscriber()
        await svc.stopTranscription()
        await svc.stopTranscription()
        #expect(await svc.stopCount == 2)
    }
}
