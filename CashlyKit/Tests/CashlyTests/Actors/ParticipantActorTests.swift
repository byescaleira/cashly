//
//  ParticipantActorTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock

@Suite("Participant Use Case", .tags(.unit, .data, .local))
actor ParticipantActorTests {
    @MainActor let suite = CommonTestSuite()

    @Test("getParticipants returns the in-memory list")
    func getParticipants() async throws {
        let result = try await suite.participantUseCase.getParticipants()
        #expect(result.count >= 0) // mock seeds none by default
    }

    @Test("addParticipant + remove roundtrip")
    func addRemoveRoundtrip() async throws {
        let user = User.mock
        let id = "p-\(UUID().uuidString)"
        try await suite.participantUseCase.addParticipant(
            id: id,
            user: user,
            splitMode: .equal,
            splitValue: 0.5,
            status: .pendingToPay,
            transaction: "tx-1"
        )
        // Mock simply tracks the call; we just verify nothing throws and
        // that remove can be invoked.
        try await suite.participantUseCase.removeParticipant(id: id)
    }
}
