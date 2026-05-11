//
//  CashlyDataFactoryTests.swift
//  CashlyKit
//
//  Verify the in-memory `init(modelContainer:)` path of
//  CashlyDataFactory. The `.make()` factory builds a CloudKit-backed
//  persistent container which we don't exercise in tests, but the
//  build-each-use-case wiring is the same code path either way.
//

import Foundation
import SwiftData
import Testing
import CashlyDomain
@testable import CashlyData

@MainActor
@Suite("CashlyDataFactory", .tags(.unit, .data, .local))
struct CashlyDataFactoryTests {

    private func makeInMemoryFactory() throws -> CashlyDataFactory {
        let schema = Schema(
            BudgetEntity.self,
            CategoryEntity.self,
            TransactionEntity.self,
            UserEntity.self,
            TagEntity.self,
            ParticipantEntity.self
        )
        let container = try ModelContainer(
            for: schema,
            configurations: .init(isStoredInMemoryOnly: true)
        )
        return CashlyDataFactory(modelContainer: container)
    }

    @Test("every makeXUseCase() returns a non-nil actor")
    func eachUseCaseBuilds() throws {
        let factory = try makeInMemoryFactory()
        _ = factory.makeAdapter()
        _ = factory.makeBudgetUseCase()
        _ = factory.makeCategoryUseCase()
        _ = factory.makeUserUseCase()
        _ = factory.makeTransactionUseCase()
        _ = factory.makeTagUseCase()
        _ = factory.makeParticipantUseCase()
    }

    @Test("BudgetActor built by the factory reads back what it writes")
    func budgetRoundtrip() async throws {
        let factory = try makeInMemoryFactory()
        let userUseCase = factory.makeUserUseCase()
        let categoryUseCase = factory.makeCategoryUseCase()
        let budgetUseCase = factory.makeBudgetUseCase()

        let user = User(id: "u-roundtrip", name: "Alice", photo: "p")
        try await userUseCase.addUser(id: user.id, name: user.name, photo: user.photo)
        let category = CashlyDomain.Category(
            id: "c-roundtrip", user: user, name: "Food", color: "#000", icon: "x"
        )
        try await categoryUseCase.addCategory(
            id: category.id, user: user.id,
            name: category.name, color: category.color, icon: category.icon
        )
        let budget = Budget(
            id: "b-roundtrip", amount: 250, category: category, date: 202604, summary: "B"
        )
        try await budgetUseCase.addBudget(
            id: budget.id, amount: budget.amount,
            category: budget.category, date: budget.date, summary: budget.summary
        )

        let fetched = try await budgetUseCase.getBudget(id: budget.id)
        #expect(fetched?.amount == 250)
        #expect(fetched?.category.id == "c-roundtrip")
    }
}
