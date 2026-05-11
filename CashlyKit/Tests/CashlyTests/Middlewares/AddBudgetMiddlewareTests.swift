//
//  AddBudgetMiddlewareTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
@testable import CashlyPresentation

@Suite("AddBudgetMiddleware", .tags(.unit, .presentation, .local))
struct AddBudgetMiddlewareTests {
    private func makeMiddleware(
        budgetUseCase: BudgetUseCaseDouble = BudgetUseCaseDouble(),
        categoryUseCase: CategoryUseCaseDouble = CategoryUseCaseDouble(),
        transactionUseCase: TransactionUseCaseDouble = TransactionUseCaseDouble(),
        userUseCase: UserUseCaseDouble = UserUseCaseDouble()
    ) -> AddBudgetMiddleware {
        AddBudgetMiddleware(
            budgetUseCase: budgetUseCase,
            categoryUseCase: categoryUseCase,
            transactionUseCase: transactionUseCase,
            userUseCase: userUseCase
        )
    }

    @Test("update emits .stopLoading")
    func updateEmitsStopLoading() async {
        let mw = makeMiddleware()
        let actions = await collectActions(from: mw.run(
            state: .new(),
            action: .update(
                categories: [],
                id: "x", amount: 0, category: nil,
                date: 202604, summary: "", isNew: true
            )
        ))
        if case .stopLoading = actions.first {} else { Issue.record("expected .stopLoading") }
    }

    @Test("passive actions emit nothing")
    func passiveActionsEmitNothing() async {
        let mw = makeMiddleware()
        for action: AddBudgetAction in [.stopLoading, .saved, .error(.onSave), .replace(.new())] {
            let actions = await collectActions(from: mw.run(state: .new(), action: action))
            #expect(actions.isEmpty)
        }
    }

    @Test("fetch emits .update with empty defaults when nothing stored")
    func fetchEmpty() async {
        let mw = makeMiddleware()
        let actions = await collectActions(from: mw.run(state: .new(), action: .fetch))
        guard case let .update(_, _, amount, _, _, summary, isNew) = actions.first
        else { Issue.record("expected .update"); return }
        #expect(amount == 0)
        #expect(summary == "")
        #expect(isNew == true)
    }

    @Test("save validates amount > 0 and summary length")
    func saveValidation() async {
        let mw = makeMiddleware()
        var state = AddBudgetState.new()
        state.amount = 0
        state.summary = "x"
        let actions = await collectActions(from: mw.run(state: state, action: .save))
        if case .error(.onSave) = actions.first {} else { Issue.record("expected .error(.onSave)") }
    }

    @Test("save throws → .error(.onSave)")
    func saveThrows() async {
        let budgetUC = BudgetUseCaseDouble()
        budgetUC.throwOnAdd = true
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let category = CashlyDomain.Category(id: "c", user: user, name: "C", color: "#000", icon: "x")
        let mw = makeMiddleware(budgetUseCase: budgetUC)
        var state = AddBudgetState.new()
        state.category = category
        state.amount = 100
        state.summary = "Valid summary"
        let actions = await collectActions(from: mw.run(state: state, action: .save))
        if case .error(.onSave) = actions.first {} else { Issue.record("expected .error(.onSave)") }
    }

    @Test("remove unknown budget emits .error(.onRemove)")
    func removeUnknown() async {
        let mw = makeMiddleware()
        var state = AddBudgetState.new()
        state.id = "ghost"
        let actions = await collectActions(from: mw.run(state: state, action: .remove))
        if case .error(.onRemove) = actions.first {} else { Issue.record("expected .error(.onRemove)") }
    }

    @Test("remove blocked by existing transactions emits .error(.onRemove)")
    func removeBlocked() async {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let category = CashlyDomain.Category(id: "c", user: user, name: "C", color: "#000", icon: "x")
        let budget = Budget(id: "b1", amount: 100, category: category, date: 202604, summary: "s")
        let budgetUC = BudgetUseCaseDouble()
        budgetUC.budgets = [budget]
        let txUC = TransactionUseCaseDouble()
        txUC.transactions = [CashlyDomain.Transaction(
            id: "tx", participants: [], budget: budget, amount: 1,
            date: 0, summary: "", status: .settled,
            splitMode: nil, splitValue: nil, paymentsPlan: nil
        )]
        let mw = makeMiddleware(budgetUseCase: budgetUC, transactionUseCase: txUC)
        var state = AddBudgetState.new()
        state.id = "b1"
        let actions = await collectActions(from: mw.run(state: state, action: .remove))
        if case .error(.onRemove) = actions.first {} else { Issue.record("expected .error(.onRemove)") }
    }
}
