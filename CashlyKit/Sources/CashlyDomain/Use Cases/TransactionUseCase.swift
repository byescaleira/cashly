//
//  TransactionUseCase.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

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
        paymentsPlan: Int?
    ) async throws
}
