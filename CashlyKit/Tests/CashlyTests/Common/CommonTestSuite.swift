//
//  CommonTestSuite.swift
//  CashlyKit
//
//  Test fixture giving each actor suite a fresh in-memory factory + a
//  full set of Use Case handles. New per-suite struct instance →
//  isolated SwiftData store.
//

import Testing
import CashlyDomain
import CashlyMock

@Suite
struct CommonTestSuite {
    let budgetUseCase: BudgetUseCase
    let categoryUseCase: CategoryUseCase
    let userUseCase: UserUseCase
    let tagUseCase: TagUseCase
    let transactionUseCase: TransactionUseCase
    let participantUseCase: ParticipantUseCase

    @MainActor
    init() {
        let factory = MockCashlyFactory()
        budgetUseCase = factory.makeBudgetUseCase()
        categoryUseCase = factory.makeCategoryUseCase()
        userUseCase = factory.makeUserUseCase()
        tagUseCase = factory.makeTagUseCase()
        transactionUseCase = factory.makeTransactionUseCase()
        participantUseCase = factory.makeParticipantUseCase()
    }

    func assertEqual<T: Equatable>(
        _ actual: T,
        _ expected: T,
        message: String? = nil
    ) {
        #expect(
            actual == expected,
            .init(stringLiteral: message ?? "Expected \(expected) but got \(actual)")
        )
    }
}
