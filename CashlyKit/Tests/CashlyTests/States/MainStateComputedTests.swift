//
//  MainStateComputedTests.swift
//  CashlyKit
//
//  Pure-function tests for MainState derived properties — score,
//  variation, remaining amount, category/budget/tag aggregations,
//  biggest* selectors, and section grouping.
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock
@testable import CashlyPresentation

@MainActor
@Suite("MainState computed", .tags(.unit, .presentation, .local))
struct MainStateComputedTests {

    @Test("budgetsAmount sums every budget.amount")
    func budgetsAmount() {
        let budgets: [Budget] = [
            Budget.mock(amount: 100),
            Budget.mock(amount: 250.5),
            Budget.mock(amount: 0)
        ]
        let state = MainState(budgets: budgets)
        #expect(state.budgetsAmount == 350.5)
    }

    @Test("remainingAmount is budgetsAmount - transactionsAmount")
    func remainingAmount() {
        let budget = Budget.mock(amount: 1000)
        let transactions = [
            Transaction.mock(budget: budget, amount: 200),
            Transaction.mock(budget: budget, amount: 300)
        ]
        let state = MainState(budgets: [budget], transactions: transactions)
        #expect(state.remainingAmount == 500)
    }

    @Test("variation = transactionsAmount / budgetsAmount, guards zero")
    func variation() {
        let empty = MainState()
        #expect(empty.variation == 0)

        let budget = Budget.mock(amount: 200)
        let tx = Transaction.mock(budget: budget, amount: 50)
        let state = MainState(budgets: [budget], transactions: [tx])
        #expect(state.variation == 0.25)
    }

    @Test("score is 1000 when variation <= 85%")
    func scoreCapsAtPerfect() {
        let budget = Budget.mock(amount: 100)
        let tx = Transaction.mock(budget: budget, amount: 50)
        let state = MainState(budgets: [budget], transactions: [tx])
        #expect(state.score.score == 1000)
    }

    @Test("score drops below 1000 once variation > 85%")
    func scoreDrops() {
        let budget = Budget.mock(amount: 100)
        let tx = Transaction.mock(budget: budget, amount: 95)
        let state = MainState(budgets: [budget], transactions: [tx])
        #expect(state.score.score < 1000)
        #expect(state.score.score > 0)
    }

    @Test("budget(for:) returns last matching budget")
    func budgetForCategory() {
        let category = CashlyDomain.Category.mock
        let b1 = Budget.mock(category: category, amount: 1)
        let b2 = Budget.mock(category: category, amount: 2)
        let other = Budget.mock(category: .mock2, amount: 999)
        let state = MainState(budgets: [b1, other, b2])
        #expect(state.budget(for: category)?.amount == 2)
        #expect(state.budget(for: .mock2)?.amount == 999)
    }

    @Test("categoriesWithBudgets / WithoutBudgets partition")
    func categoriesPartition() {
        let withBudget: CashlyDomain.Category = .mock
        let withoutBudget: CashlyDomain.Category = .mock2
        let budget = Budget.mock(category: withBudget, amount: 100)
        let state = MainState(
            budgets: [budget],
            categories: [withBudget, withoutBudget]
        )
        #expect(state.categoriesWithBudgets.contains(withBudget))
        #expect(state.categoriesWithBudgets.contains(withoutBudget) == false)
        #expect(state.categoriesWithoutBudgets.contains(withoutBudget))
        #expect(state.categoriesWithoutBudgets.contains(withBudget) == false)
    }

    @Test("biggestTransactions returns up to 5 sorted by amount desc")
    func biggestTransactions() {
        let txs = (1 ... 8).map { i in
            Transaction.mock(amount: Double(i) * 10)
        }
        let state = MainState(transactions: txs)
        let biggest = state.biggestTransactions
        #expect(biggest.count == 5)
        #expect(biggest.first?.amount == 80)
        #expect(biggest.last?.amount == 40)
    }

    // MARK: - D1 gating helpers

    @Test("isPro mirrors subscriptionStatus.tier")
    func isProMirrors() {
        var state = MainState()
        #expect(state.isPro == false)
        state.subscriptionStatus = SubscriptionStatus(tier: .pro)
        #expect(state.isPro)
    }

    @Test("canAdd(.addCategory) honours the free ceiling")
    func canAddCategoryFree() {
        let user = User(id: "u", name: "U", photo: "p")
        let categories = (0..<3).map { i in
            CashlyDomain.Category(id: "c\(i)", user: user, name: "n\(i)", color: "#000", icon: "x")
        }
        var state = MainState(categories: categories)
        #expect(state.canAdd(.addCategory) == false)
        state.subscriptionStatus = SubscriptionStatus(tier: .pro)
        #expect(state.canAdd(.addCategory))
    }

    @Test("intelligence + multiUser gated on Free")
    func freeBlocksProOnlyGates() {
        let state = MainState()
        #expect(state.canAdd(.intelligence) == false)
        #expect(state.canAdd(.multiUser) == false)
    }

    @Test("usageLabel returns n/N on Free and Pro on Pro")
    func usageLabelShape() {
        let user = User(id: "u", name: "U", photo: "p")
        var state = MainState(categories: [
            CashlyDomain.Category(id: "c1", user: user, name: "n", color: "#000", icon: "x")
        ])
        #expect(state.usageLabel(for: .addCategory) == "1/3")
        state.subscriptionStatus = SubscriptionStatus(tier: .pro)
        #expect(state.usageLabel(for: .addCategory) == "Pro")
    }
}

// MARK: - Test fixtures

private extension Budget {
    static func mock(category: CashlyDomain.Category = .mock, amount: Double) -> Budget {
        Budget(
            id: UUID().uuidString,
            amount: amount,
            category: category,
            date: 202604,
            summary: "Test budget"
        )
    }
}

private extension Transaction {
    static func mock(
        budget: Budget = Budget.mock(amount: 100),
        amount: Double = 0
    ) -> CashlyDomain.Transaction {
        CashlyDomain.Transaction(
            id: UUID().uuidString,
            participants: [],
            budget: budget,
            amount: amount,
            date: 1_700_000_000,
            summary: "Test tx",
            status: .settled,
            splitMode: nil,
            splitValue: nil,
            paymentsPlan: nil
        )
    }
}

private extension CashlyDomain.Category {
    static var mock2: CashlyDomain.Category {
        var c = CashlyDomain.Category.mock
        c.id = "mock-2"
        c.name = "Mock2"
        return c
    }
}
