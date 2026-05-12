//
//  AddCategoryMiddlewareTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock
@testable import CashlyPresentation

@Suite("AddCategoryMiddleware", .tags(.unit, .presentation, .local))
struct AddCategoryMiddlewareTests {
    private func makeMiddleware(
        budgetUseCase: BudgetUseCaseDouble = BudgetUseCaseDouble(),
        categoryUseCase: CategoryUseCaseDouble = CategoryUseCaseDouble(),
        transactionUseCase: TransactionUseCaseDouble = TransactionUseCaseDouble(),
        userUseCase: UserUseCaseDouble = UserUseCaseDouble()
    ) -> AddCategoryMiddleware {
        AddCategoryMiddleware(
            budgetUseCase: budgetUseCase,
            categoryUseCase: categoryUseCase,
            transactionUseCase: transactionUseCase,
            userUseCase: userUseCase,
            featureGate: AlwaysAllowedFeatureGate()
        )
    }

    @Test("update emits .stopLoading")
    func updateEmitsStopLoading() async {
        let mw = makeMiddleware()
        let actions = await collectActions(from: mw.run(
            state: .new(),
            action: .update(id: "x", user: nil, name: "y", color: "#000", icon: "i", isNew: true)
        ))
        if case .stopLoading = actions.first {} else { Issue.record("expected .stopLoading") }
    }

    @Test("passive actions emit nothing")
    func passiveActionsEmitNothing() async {
        let mw = makeMiddleware()
        for action: AddCategoryAction in [.stopLoading, .saved, .error(.persistence(.saveFailed(entity: "Category", underlying: "x"))), .replace(.new())] {
            let actions = await collectActions(from: mw.run(state: .new(), action: action))
            #expect(actions.isEmpty)
        }
    }

    @Test("fetch with no category falls back to state + currentUser")
    func fetchNoCategory() async {
        let userUC = UserUseCaseDouble()
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        userUC.currentUser = user
        userUC.users = [user]
        let mw = makeMiddleware(userUseCase: userUC)
        let actions = await collectActions(from: mw.run(state: .new(), action: .fetch))
        guard case let .update(_, resolvedUser, _, _, _, isNew) = actions.first
        else { Issue.record("expected .update"); return }
        #expect(resolvedUser == user)
        #expect(isNew == true)
    }

    @Test("fetch with existing category emits .update isNew=false")
    func fetchExistingCategory() async {
        let categoryUC = CategoryUseCaseDouble()
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let category = CashlyDomain.Category(id: "c1", user: user, name: "Food", color: "#FF0000", icon: "fork.knife")
        categoryUC.categories = [category]
        let userUC = UserUseCaseDouble()
        userUC.currentUser = user
        let mw = makeMiddleware(categoryUseCase: categoryUC, userUseCase: userUC)
        var state = AddCategoryState.new()
        state.id = "c1"
        let actions = await collectActions(from: mw.run(state: state, action: .fetch))
        guard case let .update(id, _, name, color, icon, isNew) = actions.first
        else { Issue.record("expected .update"); return }
        #expect(id == "c1")
        #expect(name == "Food")
        #expect(color == "#FF0000")
        #expect(icon == "fork.knife")
        #expect(isNew == false)
    }

    @Test("fetch throws → .error(.persistence(.fetchFailed))")
    func fetchThrows() async {
        let categoryUC = CategoryUseCaseDouble()
        categoryUC.throwOnGet = true
        let mw = makeMiddleware(categoryUseCase: categoryUC)
        let actions = await collectActions(from: mw.run(state: .new(), action: .fetch))
        if case .error(.persistence(.fetchFailed)) = actions.first {} else { Issue.record("expected .error(.persistence(.fetchFailed))") }
    }

    @Test("save validates name >= 3 and icon non-empty and user present")
    func saveValidation() async {
        let mw = makeMiddleware()
        var state = AddCategoryState.new()
        state.name = "ab" // too short
        state.icon = "x"
        let actions = await collectActions(from: mw.run(state: state, action: .save))
        if case .error(.domain(.invalidInput)) = actions.first {} else { Issue.record("expected .error(.domain(.invalidInput))") }
    }

    @Test("save happy path emits .saved")
    func saveHappyPath() async {
        let categoryUC = CategoryUseCaseDouble()
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let mw = makeMiddleware(categoryUseCase: categoryUC)
        var state = AddCategoryState.new()
        state.id = "newcat"
        state.user = user
        state.name = "Groceries"
        state.color = "#FF8800"
        state.icon = "cart.fill"
        let actions = await collectActions(from: mw.run(state: state, action: .save))
        if case .saved = actions.first {} else { Issue.record("expected .saved") }
    }

    @Test("remove blocked by existing budgets emits .error(.domain(.businessRuleViolated))")
    func removeBlockedByBudgets() async {
        let categoryUC = CategoryUseCaseDouble()
        let budgetUC = BudgetUseCaseDouble()
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let category = CashlyDomain.Category(id: "cat-x", user: user, name: "X", color: "#000", icon: "x")
        categoryUC.categories = [category]
        budgetUC.budgets = [
            Budget(id: "b1", amount: 1, category: category, date: 202604, summary: "s")
        ]
        let mw = makeMiddleware(budgetUseCase: budgetUC, categoryUseCase: categoryUC)
        var state = AddCategoryState.new()
        state.id = "cat-x"
        let actions = await collectActions(from: mw.run(state: state, action: .remove))
        if case .error(.domain(.businessRuleViolated)) = actions.first {} else { Issue.record("expected .error(.domain(.businessRuleViolated))") }
    }
}
