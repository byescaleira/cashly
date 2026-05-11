//
//  TransactionActorTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock

@Suite("Transaction Use Case", .tags(.unit, .data, .local))
actor TransactionActorTests {
    @MainActor let suite = CommonTestSuite()

    private func seed(category: CashlyDomain.Category, budget: Budget) async throws {
        try await suite.categoryUseCase.addCategory(
            id: category.id,
            user: category.user.id,
            name: category.name,
            color: category.color,
            icon: category.icon
        )
        try await suite.budgetUseCase.addBudget(
            id: budget.id,
            amount: budget.amount,
            category: budget.category,
            date: budget.date,
            summary: budget.summary
        )
    }

    @Test("Add then fetch transaction roundtrips")
    func roundtrip() async throws {
        let category: CashlyDomain.Category = .mock
        let budget = Budget(
            id: UUID().uuidString,
            amount: 1000,
            category: category,
            date: Date.now.timeIntervalSince1970.yearMonth,
            summary: "B"
        )
        try await seed(category: category, budget: budget)

        let txId = UUID().uuidString
        try await suite.transactionUseCase.addTransaction(
            id: txId,
            participants: [],
            budget: budget,
            amount: 42,
            date: Date.now.timeIntervalSince1970,
            summary: "Dinner",
            status: .settled,
            splitMode: nil,
            splitValue: nil,
            paymentsPlan: nil
        )

        let fetched = try await suite.transactionUseCase.getTransaction(id: txId)
        #expect(fetched?.id == txId)
        #expect(fetched?.amount == 42)
        #expect(fetched?.summary == "Dinner")
        #expect(fetched?.status == .settled)
    }

    @Test("getTransaction returns nil for unknown id")
    func unknown() async throws {
        let result = try await suite.transactionUseCase.getTransaction(id: "ghost-\(UUID().uuidString)")
        #expect(result == nil)
    }

    @Test("removeTransaction drops the row")
    func remove() async throws {
        let category: CashlyDomain.Category = .mock
        let budget = Budget(
            id: UUID().uuidString,
            amount: 100,
            category: category,
            date: Date.now.timeIntervalSince1970.yearMonth,
            summary: "B"
        )
        try await seed(category: category, budget: budget)

        let txId = UUID().uuidString
        try await suite.transactionUseCase.addTransaction(
            id: txId,
            participants: [],
            budget: budget,
            amount: 1,
            date: Date.now.timeIntervalSince1970,
            summary: "Doomed",
            status: .settled,
            splitMode: nil,
            splitValue: nil,
            paymentsPlan: nil
        )
        try await suite.transactionUseCase.removeTransaction(id: txId)
        let result = try await suite.transactionUseCase.getTransaction(id: txId)
        #expect(result == nil)
    }
}
