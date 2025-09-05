//
//  MockParticipantActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

import RyzeFoundation
import CashlyDomain
import SwiftData

actor MockParticipantActor: ParticipantUseCase {
    var participants = Participant.mocks
    let users = User.mocks
    
    init() {}
    
    func getParticipant(id: String) async throws -> Participant? {
        participants.first(where: { $0.id == id })
    }
    
    func getParticipants() async throws -> [Participant] {
        participants
    }
    
    func getParticipants(transaction: String) async throws -> [Participant] {
        participants.filter { $0.transaction == transaction }
    }
    
    func removeParticipant(id: String) async throws {
        guard let tag = try await getParticipant(id: id),
              let index = participants.firstIndex(of: tag)
        else { return }
        let _ = participants.remove(at: index)
    }
    
    func removeParticipants() async throws {
        participants = []
    }
    
    func addParticipant(
        id: String,
        user: User,
        splitMode: TransactionSplitMode,
        splitValue: Double,
        status: TransactionStatus,
        transaction: String
    ) async throws {
        let tag = Participant(
            id: id,
            user: user,
            splitMode: splitMode,
            splitValue: splitValue,
            status: status,
            transaction: transaction
        )
        participants.append(tag)
    }
}

