//
//  TransactionUseCase.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import Foundation

public protocol TransactionUseCase: Sendable {
    func getTransaction(id: String) async throws -> Transaction?
    func getTransactions() async throws -> [Transaction]
    func getTransactions(
        budgets: [String]?,
        tags: [String]?,
        statuses: [Int]?,
        participants: [String]?,
        date: Date?
    ) async throws -> [Transaction]
    func removeTransaction(id: String) async throws
    func removeTransactions(ids: Set<String>) async throws
    func removeTransactions() async throws
    func addTransaction(
        id: String,
        participants: [Participant],
        budget: Budget,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: TransactionStatus,
        splitMode: TransactionSplitMode?,
        splitValue: Double?,
        paymentsPlan: Int?,
        kind: TransactionKind,
        needsReview: Bool
    ) async throws
}

public extension TransactionUseCase {
    /// Back-compat wrapper. Pre-J2 callsites still pass nine
    /// parameters; defaults match the entity-side defaults.
    func addTransaction(
        id: String,
        participants: [Participant],
        budget: Budget,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: TransactionStatus,
        splitMode: TransactionSplitMode?,
        splitValue: Double?,
        paymentsPlan: Int?
    ) async throws {
        try await addTransaction(
            id: id,
            participants: participants,
            budget: budget,
            amount: amount,
            date: date,
            summary: summary,
            status: status,
            splitMode: splitMode,
            splitValue: splitValue,
            paymentsPlan: paymentsPlan,
            kind: .expense,
            needsReview: false
        )
    }
}
