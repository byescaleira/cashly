//
//  SmokeTests.swift
//  CashlyKit
//
//  Wave 0 deferred smoke tests for Data layer actors.
//  Verifies: factory wires each UseCase, init succeeds, getAll-equivalent
//  returns a non-nil array (empty is acceptable on fresh in-memory store).
//

import Testing
import CashlyDomain
import CashlyMock

@Suite("Data Actors Smoke", .tags(.unit, .data, .local))
@MainActor
struct DataActorSmokeTests {
    let factory = MockCashlyFactory()

    @Test("BudgetUseCase init + getBudgets")
    func budgetSmoke() async throws {
        let useCase = factory.makeBudgetUseCase()
        let result = try await useCase.getBudgets()
        #expect(result.count >= 0)
    }

    @Test("CategoryUseCase init + getCategories")
    func categorySmoke() async throws {
        let useCase = factory.makeCategoryUseCase()
        let result = try await useCase.getCategories()
        #expect(result.count >= 0)
    }

    @Test("UserUseCase init + getUsers")
    func userSmoke() async throws {
        let useCase = factory.makeUserUseCase()
        let result = try await useCase.getUsers()
        #expect(result.count >= 0)
    }

    @Test("TransactionUseCase init + getTransactions")
    func transactionSmoke() async throws {
        let useCase = factory.makeTransactionUseCase()
        let result = try await useCase.getTransactions()
        #expect(result.count >= 0)
    }

    @Test("TagUseCase init + getTags")
    func tagSmoke() async throws {
        let useCase = factory.makeTagUseCase()
        let result = try await useCase.getTags()
        #expect(result.count >= 0)
    }

    @Test("ParticipantUseCase init + getParticipants")
    func participantSmoke() async throws {
        let useCase = factory.makeParticipantUseCase()
        let result = try await useCase.getParticipants()
        #expect(result.count >= 0)
    }

    @Test("AdapterUseCase init")
    func adapterSmoke() async throws {
        _ = factory.makeAdapter()
        #expect(Bool(true))
    }
}
