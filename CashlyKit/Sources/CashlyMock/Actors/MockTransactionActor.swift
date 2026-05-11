//
import Foundation
//  MockTransactionActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import PrismFoundation
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
        statuses: [Int]?,
        participants: [String]?,
        date: Date?
    ) async throws -> [CashlyDomain.Transaction] {
        let budgetIDs = budgets ?? []
        let tagValues = tags ?? []
        let statusValues = statuses ?? []
        let participantIDs = participants ?? []
        return transactions.filter { transaction in
            (budgetIDs.isEmpty || budgetIDs.contains(transaction.budget.id)) &&
            (tagValues.isEmpty || tagValues.contains(where: { transaction.summary.contains($0) })) &&
            (statusValues.isEmpty || statusValues.contains(where: { transaction.status.rawValue == $0 })) &&
            (participantIDs.isEmpty || !Set(transaction.participants.map(\.id)).isDisjoint(with: participantIDs)) &&
            (date != nil ? transaction.date.yearMonth == date?.timeIntervalSince1970.yearMonth : true)
        }
    }
    
    func removeTransaction(id: String) async throws {
        guard let transaction = try await getTransaction(id: id),
              let index = transactions.firstIndex(of: transaction)
        else { return }
        let _ = transactions.remove(at: index)
    }
    
    func removeTransactions(ids: Set<String>) async throws {
        transactions.removeAll(where: {
            !ids.contains($0.id)
        })
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
        status: TransactionStatus,
        splitMode: TransactionSplitMode?,
        splitValue: Double?,
        paymentsPlan: Int?
    ) async throws {
        let transaction = CashlyDomain.Transaction(
            id: id,
            participants: participants,
            budget: budget,
            amount: amount,
            date: date,
            summary: summary,
            status: status,
            splitMode: splitMode,
            splitValue: splitValue,
            paymentsPlan: paymentsPlan
        )
        transactions.append(transaction)
    }
}
