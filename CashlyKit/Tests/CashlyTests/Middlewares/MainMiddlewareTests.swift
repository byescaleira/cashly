//
//  MainMiddlewareTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
@testable import CashlyPresentation

@Suite("MainMiddleware", .tags(.unit, .presentation, .local))
struct MainMiddlewareTests {
    private func makeMiddleware(
        budgetUseCase: BudgetUseCaseDouble = BudgetUseCaseDouble(),
        categoryUseCase: CategoryUseCaseDouble = CategoryUseCaseDouble(),
        transactionUseCase: TransactionUseCaseDouble = TransactionUseCaseDouble(),
        tagUseCase: TagUseCaseDouble = TagUseCaseDouble(),
        userUseCase: UserUseCaseDouble = UserUseCaseDouble()
    ) -> MainMiddleware {
        MainMiddleware(
            budgetUseCase: budgetUseCase,
            categoryUseCase: categoryUseCase,
            transactionUseCase: transactionUseCase,
            tagUseCase: tagUseCase,
            userUseCase: userUseCase
        )
    }

    @Test("update emits .stopLoading")
    func updateEmitsStopLoading() async {
        let mw = makeMiddleware()
        let actions = await collectActions(from: mw.run(
            state: MainState(),
            action: .update(
                filter: FilterState(),
                budgets: [], categories: [], transactions: [],
                tags: [], users: [], user: nil,
                predictedTransactionsAmount: 0
            )
        ))
        if case .stopLoading = actions.first {} else { Issue.record("expected .stopLoading") }
    }

    @Test("error / stopLoading / replace emit nothing")
    func passiveActionsEmitNothing() async {
        let mw = makeMiddleware()
        for action: MainAction in [.error(.persistence(.saveFailed(entity: "x", underlying: "x"))), .stopLoading, .replace(MainState())] {
            let actions = await collectActions(from: mw.run(state: MainState(), action: action))
            #expect(actions.isEmpty)
        }
    }

    @Test("removeTag with no matching tag emits .error(.persistence(.notFound))")
    func removeTagUnknown() async {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let tag = Tag(id: "t-ghost", user: user, name: "Ghost", color: "#000", icon: "x")
        let mw = makeMiddleware()
        let actions = await collectActions(from: mw.run(state: MainState(), action: .removeTag(tag)))
        if case .error(.persistence(.notFound)) = actions.first {} else { Issue.record("expected .error(.persistence(.notFound))") }
    }

    @Test("removeTag with matching tag emits .fetch")
    func removeTagFound() async {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let tag = Tag(id: "t1", user: user, name: "Coffee", color: "#000", icon: "x")
        let tagUC = TagUseCaseDouble()
        tagUC.tags = [tag]
        let mw = makeMiddleware(tagUseCase: tagUC)
        let actions = await collectActions(from: mw.run(state: MainState(), action: .removeTag(tag)))
        if case .fetch = actions.first {} else { Issue.record("expected .fetch") }
    }

    @Test("removeTransaction emits .fetch on success")
    func removeTransactionSuccess() async {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let category = CashlyDomain.Category(id: "c", user: user, name: "C", color: "#000", icon: "x")
        let budget = Budget(id: "b", amount: 100, category: category, date: 202604, summary: "s")
        let tx = CashlyDomain.Transaction(
            id: "tx-1", participants: [], budget: budget, amount: 50,
            date: 0, summary: "Dinner", status: .settled,
            splitMode: nil, splitValue: nil, paymentsPlan: nil
        )
        let mw = makeMiddleware()
        let actions = await collectActions(from: mw.run(state: MainState(), action: .removeTransaction(tx)))
        if case .fetch = actions.first {} else { Issue.record("expected .fetch") }
    }

    @Test("removeTransactions emits .fetch on success")
    func removeTransactionsSuccess() async {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let category = CashlyDomain.Category(id: "c", user: user, name: "C", color: "#000", icon: "x")
        let budget = Budget(id: "b", amount: 100, category: category, date: 202604, summary: "s")
        let txs: Set<CashlyDomain.Transaction> = [
            CashlyDomain.Transaction(
                id: "tx-1", participants: [], budget: budget, amount: 1,
                date: 0, summary: "x", status: .settled,
                splitMode: nil, splitValue: nil, paymentsPlan: nil
            )
        ]
        let mw = makeMiddleware()
        let actions = await collectActions(from: mw.run(state: MainState(), action: .removeTransactions(txs)))
        if case .fetch = actions.first {} else { Issue.record("expected .fetch") }
    }

    @Test("selectUser with nil user emits .error(.domain(.invalidInput))")
    func selectUserNil() async {
        let mw = makeMiddleware()
        let actions = await collectActions(from: mw.run(state: MainState(), action: .selectUser))
        if case .error(.domain(.invalidInput)) = actions.first {} else { Issue.record("expected .error(.domain(.invalidInput))") }
    }

    @Test("selectUser with user emits .fetch")
    func selectUserPresent() async {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let mw = makeMiddleware()
        let state = MainState(user: user)
        let actions = await collectActions(from: mw.run(state: state, action: .selectUser))
        if case .fetch = actions.first {} else { Issue.record("expected .fetch") }
    }

    @Test("fetch emits .update with resolved entities")
    func fetchEmitsUpdate() async {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let category = CashlyDomain.Category(id: "c", user: user, name: "C", color: "#000", icon: "x")
        let budget = Budget(id: "b", amount: 100, category: category, date: 202604, summary: "s")
        let categoryUC = CategoryUseCaseDouble()
        categoryUC.categories = [category]
        let budgetUC = BudgetUseCaseDouble()
        budgetUC.budgets = [budget]
        let userUC = UserUseCaseDouble()
        userUC.users = [user]
        userUC.currentUser = user
        let mw = makeMiddleware(budgetUseCase: budgetUC, categoryUseCase: categoryUC, userUseCase: userUC)
        let actions = await collectActions(from: mw.run(state: MainState(), action: .fetch))
        guard case let .update(_, gotBudgets, gotCategories, _, _, gotUsers, gotUser, _) = actions.first
        else { Issue.record("expected .update"); return }
        #expect(gotBudgets.contains(where: { $0.id == budget.id }))
        #expect(gotCategories.contains(where: { $0.id == category.id }))
        #expect(gotUsers.contains(where: { $0.id == user.id }))
        #expect(gotUser?.id == user.id)
    }
}
