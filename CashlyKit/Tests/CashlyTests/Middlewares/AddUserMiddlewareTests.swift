//
//  AddUserMiddlewareTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
@testable import CashlyPresentation

@Suite("AddUserMiddleware", .tags(.unit, .presentation, .local))
struct AddUserMiddlewareTests {

    private func makeMiddleware(
        userUseCase: UserUseCaseDouble = UserUseCaseDouble(),
        budgetUseCase: BudgetUseCaseDouble = BudgetUseCaseDouble(),
        categoryUseCase: CategoryUseCaseDouble = CategoryUseCaseDouble(),
        transactionUseCase: TransactionUseCaseDouble = TransactionUseCaseDouble()
    ) -> AddUserMiddleware {
        AddUserMiddleware(
            budgetUseCase: budgetUseCase,
            categoryUseCase: categoryUseCase,
            transactionUseCase: transactionUseCase,
            userUseCase: userUseCase
        )
    }

    @Test("update emits stopLoading")
    func updateEmitsStopLoading() async {
        let mw = makeMiddleware()
        let state = AddUserState.new()
        let effect = mw.run(state: state, action: .update(id: "x", name: "y", photo: nil, isNew: true))
        let actions = await collectActions(from: effect)
        #expect(actions.count == 1)
        if case .stopLoading = actions.first {} else { Issue.record("expected .stopLoading") }
    }

    @Test("stopLoading / saved / error / replace emit nothing")
    func passiveActionsEmitNothing() async {
        let mw = makeMiddleware()
        let state = AddUserState.new()
        for action: AddUserAction in [.stopLoading, .saved, .error(.onSave), .replace(state)] {
            let actions = await collectActions(from: mw.run(state: state, action: action))
            #expect(actions.isEmpty, "expected no emissions for \(action)")
        }
    }

    @Test("fetch with no user found emits .update with isNew=true")
    func fetchUnknownUser() async {
        let userUC = UserUseCaseDouble()
        let mw = makeMiddleware(userUseCase: userUC)
        let state = AddUserState.new()
        let actions = await collectActions(from: mw.run(state: state, action: .fetch))
        #expect(actions.count == 1)
        guard case let .update(id, name, photo, isNew) = actions.first
        else { Issue.record("expected .update"); return }
        #expect(id == state.id)
        #expect(name == state.name)
        #expect(photo == state.photo)
        #expect(isNew == true)
    }

    @Test("fetch with existing user emits .update with isNew=false")
    func fetchExistingUser() async {
        let userUC = UserUseCaseDouble()
        let existing = User(id: "u1", name: "Alice", photo: "https://x/a.png")
        userUC.users = [existing]
        let mw = makeMiddleware(userUseCase: userUC)
        var state = AddUserState.new()
        state.id = "u1"
        let actions = await collectActions(from: mw.run(state: state, action: .fetch))
        guard case let .update(id, name, photo, isNew) = actions.first
        else { Issue.record("expected .update"); return }
        #expect(id == "u1")
        #expect(name == "Alice")
        #expect(photo == "https://x/a.png")
        #expect(isNew == false)
    }

    @Test("fetch throws → emits .error(.onFetch)")
    func fetchThrows() async {
        let userUC = UserUseCaseDouble()
        userUC.throwOnGet = true
        let mw = makeMiddleware(userUseCase: userUC)
        let actions = await collectActions(from: mw.run(state: .new(), action: .fetch))
        if case .error(.onFetch) = actions.first {} else { Issue.record("expected .error(.onFetch)") }
    }

    @Test("save with short name emits .error(.onSave) without DB write")
    func saveValidatesNameLength() async {
        let userUC = UserUseCaseDouble()
        let mw = makeMiddleware(userUseCase: userUC)
        var state = AddUserState.new()
        state.name = "ab"
        state.photo = "https://x/p.png"
        let actions = await collectActions(from: mw.run(state: state, action: .save))
        if case .error(.onSave) = actions.first {} else { Issue.record("expected .error(.onSave)") }
        #expect(userUC.addUserCalls.calls.isEmpty)
    }

    @Test("save with invalid photo URL emits .error(.onSave)")
    func saveValidatesPhotoURL() async {
        let userUC = UserUseCaseDouble()
        let mw = makeMiddleware(userUseCase: userUC)
        var state = AddUserState.new()
        state.name = "Valid Name"
        state.photo = nil
        let actions = await collectActions(from: mw.run(state: state, action: .save))
        if case .error(.onSave) = actions.first {} else { Issue.record("expected .error(.onSave)") }
        #expect(userUC.addUserCalls.calls.isEmpty)
    }

    @Test("save happy path calls addUser+selectUser and emits .saved")
    func saveHappyPath() async {
        let userUC = UserUseCaseDouble()
        let mw = makeMiddleware(userUseCase: userUC)
        var state = AddUserState.new()
        state.id = "new-id"
        state.name = "Alice"
        state.photo = "https://x/a.png"
        let actions = await collectActions(from: mw.run(state: state, action: .save))
        if case .saved = actions.first {} else { Issue.record("expected .saved") }
        #expect(userUC.addUserCalls.calls.count == 1)
        #expect(userUC.addUserCalls.calls.first?.id == "new-id")
        #expect(userUC.addUserCalls.calls.first?.name == "Alice")
        #expect(userUC.selectUserCalls.calls.count == 1)
    }

    @Test("save propagates addUser throw as .error(.onSave)")
    func saveAddThrows() async {
        let userUC = UserUseCaseDouble()
        userUC.throwOnAdd = true
        let mw = makeMiddleware(userUseCase: userUC)
        var state = AddUserState.new()
        state.name = "Alice"
        state.photo = "https://x/a.png"
        let actions = await collectActions(from: mw.run(state: state, action: .save))
        if case .error(.onSave) = actions.first {} else { Issue.record("expected .error(.onSave)") }
    }

    @Test("remove with empty deps and existing user emits .saved")
    func removeHappyPath() async {
        let userUC = UserUseCaseDouble()
        let user = User(id: "remove-me", name: "Bob", photo: "https://x/b.png")
        userUC.users = [user]
        let mw = makeMiddleware(userUseCase: userUC)
        var state = AddUserState.new()
        state.id = "remove-me"
        let actions = await collectActions(from: mw.run(state: state, action: .remove))
        if case .saved = actions.first {} else { Issue.record("expected .saved") }
        #expect(userUC.removeUserCalls.calls.contains("remove-me"))
    }

    @Test("remove with related categories emits .error(.onRemove)")
    func removeBlockedByDependencies() async {
        let userUC = UserUseCaseDouble()
        let user = User(id: "u-blocked", name: "Carol", photo: "https://x/c.png")
        userUC.users = [user]
        let categoryUC = CategoryUseCaseDouble()
        categoryUC.categories = [
            CashlyDomain.Category(id: "cat", user: user, name: "Food", color: "#000", icon: "fork.knife")
        ]
        let mw = makeMiddleware(userUseCase: userUC, categoryUseCase: categoryUC)
        var state = AddUserState.new()
        state.id = "u-blocked"
        let actions = await collectActions(from: mw.run(state: state, action: .remove))
        if case .error(.onRemove) = actions.first {} else { Issue.record("expected .error(.onRemove)") }
        #expect(userUC.removeUserCalls.calls.isEmpty)
    }
}
