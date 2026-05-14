//
//  DefaultFeatureGateTests.swift
//  CashlyKit
//
//  Exercises the Free/Pro decision matrix. Uses the in-memory
//  subscription service to flip tier, the mock use cases as the count
//  source, and verifies each FeatureGate case maps to .allowed or
//  .blocked as the free-tier limits dictate.
//

import Foundation
import Testing
import CashlyDomain
import CashlyData
import CashlyMock

@Suite("Default Feature Gate", .tags(.unit, .data, .local))
struct DefaultFeatureGateTests {

    private func makeGate(
        subscription: InMemorySubscriptionService = InMemorySubscriptionService(),
        users: [User] = [],
        categories: [CashlyDomain.Category] = [],
        budgets: [Budget] = [],
        limits: FeatureGateLimits = .freeDefault
    ) -> DefaultFeatureGate {
        let userUC = MockUserSeed.makeUserCase(users: users)
        let categoryUC = MockCategorySeed.makeCategoryCase(categories: categories)
        let budgetUC = MockBudgetSeed.makeBudgetCase(budgets: budgets)
        return DefaultFeatureGate(
            subscription: subscription,
            userUseCase: userUC,
            categoryUseCase: categoryUC,
            budgetUseCase: budgetUC,
            limits: limits
        )
    }

    @Test("free tier with no entities → addCategory allowed")
    func freeAllowsFirstCategory() async {
        let gate = makeGate(limits: .freeDefault)
        let decision = await gate.decide(.addCategory)
        #expect(decision.isAllowed)
    }

    @Test("free tier at category ceiling → addCategory blocked")
    func freeBlocksAtCategoryCeiling() async {
        let cats = (0..<3).map { i in
            CashlyDomain.Category(
                id: "c\(i)",
                user: User(id: "u", name: "U", photo: "p"),
                name: "n\(i)",
                color: "#000",
                icon: "x"
            )
        }
        let gate = makeGate(categories: cats)
        let decision = await gate.decide(.addCategory)
        if case let .blocked(feature, tier) = decision {
            #expect(feature == .addCategory)
            #expect(tier == .pro)
        } else {
            Issue.record("expected .blocked")
        }
    }

    @Test("pro tier ignores all limits")
    func proAllowsEverything() async {
        let subscription = InMemorySubscriptionService()
        await subscription.setTier(.pro)
        let cats = (0..<10).map { i in
            CashlyDomain.Category(
                id: "c\(i)",
                user: User(id: "u", name: "U", photo: "p"),
                name: "n\(i)",
                color: "#000",
                icon: "x"
            )
        }
        let gate = makeGate(subscription: subscription, categories: cats)
        #expect(await gate.decide(.addCategory).isAllowed)
        #expect(await gate.decide(.addBudget).isAllowed)
        #expect(await gate.decide(.addUser).isAllowed)
        #expect(await gate.decide(.intelligence).isAllowed)
        #expect(await gate.decide(.multiUser).isAllowed)
    }

    @Test("free tier blocks intelligence regardless of count")
    func freeBlocksIntelligence() async {
        let gate = makeGate()
        let decision = await gate.decide(.intelligence)
        if case .blocked = decision {} else { Issue.record("expected .blocked") }
    }

    @Test("free tier blocks multiUser regardless of count")
    func freeBlocksMultiUser() async {
        let gate = makeGate()
        let decision = await gate.decide(.multiUser)
        if case .blocked = decision {} else { Issue.record("expected .blocked") }
    }

    @Test("custom limits raise the ceiling")
    func customLimits() async {
        let cats = (0..<3).map { i in
            CashlyDomain.Category(
                id: "c\(i)",
                user: User(id: "u", name: "U", photo: "p"),
                name: "n\(i)",
                color: "#000",
                icon: "x"
            )
        }
        let gate = makeGate(
            categories: cats,
            limits: FeatureGateLimits(maxUsers: 5, maxCategories: 10, maxBudgets: 20)
        )
        #expect(await gate.decide(.addCategory).isAllowed)
    }
}

// MARK: - Local seedable doubles

/// Minimal seeders so the tests don't depend on UserUseCaseDouble's
/// internal storage details. The gate only calls getUsers /
/// getCategories / getBudgets — every other method can throw.
private enum MockUserSeed {
    static func makeUserCase(users: [User]) -> UserUseCase {
        SeededUserUseCase(users: users)
    }
}

private enum MockCategorySeed {
    static func makeCategoryCase(categories: [CashlyDomain.Category]) -> CategoryUseCase {
        SeededCategoryUseCase(categories: categories)
    }
}

private enum MockBudgetSeed {
    static func makeBudgetCase(budgets: [Budget]) -> BudgetUseCase {
        SeededBudgetUseCase(budgets: budgets)
    }
}

private actor SeededUserUseCase: UserUseCase {
    let users: [User]
    init(users: [User]) { self.users = users }
    func getUser(id: String) async throws -> User? { users.first { $0.id == id } }
    func getCurrentUser() async throws -> User? { users.first }
    func selectUser(user: User) async throws {}
    func getUsers() async throws -> [User] { users }
    func removeUser(id: String) async throws {}
    func removeUsers() async throws {}
    func addUser(id: String, name: String, photo: String) async throws {}
}

private actor SeededCategoryUseCase: CategoryUseCase {
    let categories: [CashlyDomain.Category]
    init(categories: [CashlyDomain.Category]) { self.categories = categories }
    func getCategory(id: String) async throws -> CashlyDomain.Category? { categories.first { $0.id == id } }
    func getCategories() async throws -> [CashlyDomain.Category] { categories }
    func getCategories(ids: [String]?, users: [String]?) async throws -> [CashlyDomain.Category] { categories }
    func removeCategory(id: String) async throws {}
    func removeCategories() async throws {}
    func addCategory(id: String, user: String, name: String, color: String, icon: String, order: Int) async throws {}
    func reorderCategories(ids: [String]) async throws {}
}

private actor SeededBudgetUseCase: BudgetUseCase {
    let budgets: [Budget]
    init(budgets: [Budget]) { self.budgets = budgets }
    func getBudget(id: String) async throws -> Budget? { budgets.first { $0.id == id } }
    func getBudgets() async throws -> [Budget] { budgets }
    func getBudgets(categories: [String]?, date: Date?) async throws -> [Budget] { budgets }
    func removeBudget(id: String) async throws {}
    func removeBudgets() async throws {}
    func addBudget(id: String, amount: Double, category: CashlyDomain.Category, date: Int, summary: String, rollsOver: Bool) async throws {}
}
