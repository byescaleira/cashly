//
//  MockTransactionActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import RyzeFoundation
import CashlyDomain
import SwiftData

actor MockTransactionActor: TransactionUseCase {
    let budgets = Budget.mocks
    var transactions = CashlyDomain.Transaction.mocks
    
    init() {}
    
    func getTransaction(id: String) async throws -> CashlyDomain.Transaction? {
        transactions.first(where: { $0.id == id })
    }
    
    func getTransactions() async throws -> [CashlyDomain.Transaction] {
        transactions
    }
    
    func getTransactions(
        budgets: [String]?,
        tags: [String]?,
        date: Date?
    ) async throws -> [CashlyDomain.Transaction] {
        transactions.filter { transaction in
            (budgets?.isEmpty == false ? budgets!.contains(transaction.budget.id) : true) &&
            (tags?.isEmpty == false ? tags!.contains(where: { transaction.summary.contains($0) }) : true) &&
            (date != nil ? transaction.date.yearMonth == date?.timeIntervalSince1970.yearMonth : true)
        }
    }
    
    func removeTransaction(id: String) async throws {
        guard let transaction = try await getTransaction(id: id),
              let index = transactions.firstIndex(of: transaction)
        else { return }
        let _ = transactions.remove(at: index)
    }
    
    func removeTransactions() async throws {
        transactions = []
    }
    
    func addTransaction(
        id: String,
        participants: [Participant],
        budget: Budget,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: TransactionStatus
    ) async throws {
        let transaction = CashlyDomain.Transaction(
            id: id,
            participants: participants,
            budget: budget,
            amount: amount,
            date: date,
            summary: summary,
            status: status
        )
        transactions.append(transaction)
    }
}
