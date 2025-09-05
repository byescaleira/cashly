//
//  ParticipantUseCase.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

public protocol ParticipantUseCase: Sendable {
    func getParticipant(id: String) async throws -> Participant?
    func getParticipants() async throws -> [Participant]
    func getParticipants(transaction: String) async throws -> [Participant]
    func removeParticipant(id: String) async throws
    func removeParticipants() async throws
    func addParticipant(
        id: String,
        user: User,
        splitMode: TransactionSplitMode,
        splitValue: Double,
        status: TransactionStatus,
        transaction: String
    ) async throws
}
