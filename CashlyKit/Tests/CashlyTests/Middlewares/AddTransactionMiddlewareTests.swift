//
//  AddTransactionMiddlewareTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
@testable import CashlyPresentation

@Suite("AddTransactionMiddleware", .tags(.unit, .presentation, .local))
struct AddTransactionMiddlewareTests {
    private func makeMiddleware(
        budgetUseCase: BudgetUseCaseDouble = BudgetUseCaseDouble(),
        categoryUseCase: CategoryUseCaseDouble = CategoryUseCaseDouble(),
        transactionUseCase: TransactionUseCaseDouble = TransactionUseCaseDouble(),
        tagUseCase: TagUseCaseDouble = TagUseCaseDouble(),
        userUseCase: UserUseCaseDouble = UserUseCaseDouble(),
        participantUseCase: ParticipantUseCaseDouble = ParticipantUseCaseDouble()
    ) -> AddTransactionMiddleware {
        AddTransactionMiddleware(
            budgetUseCase: budgetUseCase,
            categoryUseCase: categoryUseCase,
            transactionUseCase: transactionUseCase,
            tagUseCase: tagUseCase,
            userUseCase: userUseCase,
            participantUseCase: participantUseCase
        )
    }

    @Test("update emits .stopLoading")
    func updateEmitsStopLoading() async {
        let mw = makeMiddleware()
        let actions = await collectActions(from: mw.run(
            state: .new(),
            action: .update(
                budgets: [], id: "x", participants: [], budget: nil,
                amount: 0, date: .now, summary: "", status: .settled,
                splitMode: nil, splitValue: nil, tags: [],
                isNew: true, installmentIsOn: false, installmentPlan: 1
            )
        ))
        if case .stopLoading = actions.first {} else { Issue.record("expected .stopLoading") }
    }

    @Test("passive actions emit nothing")
    func passiveActionsEmitNothing() async {
        let mw = makeMiddleware()
        for action: AddTransactionAction in [.stopLoading, .saved, .error(.onSave), .replace(.new())] {
            let actions = await collectActions(from: mw.run(state: .new(), action: action))
            #expect(actions.isEmpty)
        }
    }

    @Test("save validation fails on missing budget")
    func saveValidationMissingBudget() async {
        let mw = makeMiddleware()
        var state = AddTransactionState.new()
        state.amount = 100
        state.summary = "Valid summary"
        let actions = await collectActions(from: mw.run(state: state, action: .save))
        if case .error(.onSave) = actions.first {} else { Issue.record("expected .error(.onSave)") }
    }

    @Test("save validation fails on short summary")
    func saveValidationShortSummary() async {
        let mw = makeMiddleware()
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let category = CashlyDomain.Category(id: "c", user: user, name: "C", color: "#000", icon: "x")
        let budget = Budget(id: "b", amount: 200, category: category, date: 202604, summary: "s")
        var state = AddTransactionState.new()
        state.budget = budget
        state.amount = 50
        state.summary = "ab"
        let actions = await collectActions(from: mw.run(state: state, action: .save))
        if case .error(.onSave) = actions.first {} else { Issue.record("expected .error(.onSave)") }
    }

    @Test("remove unknown transaction emits .error(.onRemove)")
    func removeUnknown() async {
        let mw = makeMiddleware()
        var state = AddTransactionState.new()
        state.id = "ghost"
        let actions = await collectActions(from: mw.run(state: state, action: .remove))
        if case .error(.onRemove) = actions.first {} else { Issue.record("expected .error(.onRemove)") }
    }

    @Test("remove existing transaction emits .saved")
    func removeHappyPath() async {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let category = CashlyDomain.Category(id: "c", user: user, name: "C", color: "#000", icon: "x")
        let budget = Budget(id: "b", amount: 200, category: category, date: 202604, summary: "s")
        let tx = CashlyDomain.Transaction(
            id: "tx-1", participants: [], budget: budget, amount: 50,
            date: 0, summary: "Dinner", status: .settled,
            splitMode: nil, splitValue: nil, paymentsPlan: nil
        )
        let txUC = TransactionUseCaseDouble()
        txUC.transactions = [tx]
        let mw = makeMiddleware(transactionUseCase: txUC)
        var state = AddTransactionState.new()
        state.id = "tx-1"
        let actions = await collectActions(from: mw.run(state: state, action: .remove))
        if case .saved = actions.first {} else { Issue.record("expected .saved") }
    }
}
