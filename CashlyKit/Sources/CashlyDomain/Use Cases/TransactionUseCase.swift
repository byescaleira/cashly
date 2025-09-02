//
//  TransactionUseCase.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

public protocol TransactionUseCase: Sendable {
    func getTransaction(id: UUID) async throws -> Transaction?
    func getTransactions() async throws -> [Transaction]
    func getTransactions(
        budget: UUID?,
        category: UUID?,
        date: Date?
    ) async throws -> [Transaction]
    func removeTransaction(id: UUID) async throws
    func removeTransactions() async throws
    func addTransaction(
        id: UUID,
        user: User,
        participants: [User],
        category: Category,
        amount: Double,
        date: Date,
        summary: String,
        status: TransactionStatus
    ) async throws
}
