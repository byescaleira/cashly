//
//  ReducerCompositionTests.swift
//  CashlyKit
//
//  PrismStore.init(initialState:reducer:middleware:) composes the
//  reducer with the middleware via `reducer.handling(with: middleware)`.
//  Dispatching an action must run the reducer arm AND emit the
//  middleware's effect actions. Drive the composite store end-to-end.
//

import Foundation
import Testing
import CashlyDomain
@testable import CashlyPresentation

@MainActor
@Suite("Reducer + Middleware composition", .tags(.unit, .presentation, .local))
struct ReducerCompositionTests {

    @Test("AddUser store: .update sets fields AND middleware emits .stopLoading")
    func updateThenStopLoading() async {
        let store = makeAddUserStore()
        store.send(.update(id: "u1", name: "Alice", photo: "https://x/a.png", isNew: false))

        // Poll up to 2s for the async middleware effect to land.
        for _ in 0 ..< 200 where store.state.isLoading == true {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms tick
        }

        #expect(store.state.id == "u1")
        #expect(store.state.name == "Alice")
        #expect(store.state.photo == "https://x/a.png")
        #expect(store.state.isNew == false)
        #expect(store.state.isLoading == false) // <-- stopLoading from middleware
    }

    @Test("AddCategory store: .saved sets isSaved and middleware emits nothing")
    func savedNoMiddlewareCascade() async {
        let store = makeAddCategoryStore()
        store.send(.saved)
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(store.state.isSaved == true)
    }

    @Test("AddTag store: .replace swaps state and middleware emits nothing")
    func replaceDoesNotCascade() async {
        let store = makeAddTagStore()
        let target = AddTagState.edit(id: "tag-replaced")
        store.send(.replace(target))
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(store.state.id == "tag-replaced")
    }

    @Test("AddUser store: .fetch flips isLoading=true synchronously")
    func fetchSetsLoadingSync() async {
        let store = makeAddUserStore()
        store.cashlyMutate(\.isLoading, false)
        try? await Task.sleep(nanoseconds: 100_000_000)
        // Reducer arm runs synchronously inside send(); middleware effect
        // is async. Right after send(.fetch) state.isLoading should be true.
        store.send(.fetch)
        #expect(store.state.isLoading == true)
    }

    @Test("MainStore: .error sets state.error but emits no follow-up actions")
    func errorTerminates() async {
        let store = makeMainStore()
        store.send(.error(.onFetch))
        try? await Task.sleep(nanoseconds: 100_000_000)
        if case .onFetch = store.state.error {} else {
            Issue.record("expected state.error == .onFetch")
        }
    }

    // MARK: - Fixtures

    private func makeAddUserStore() -> CashlyStore<AddUserState, AddUserAction> {
        let factory = TestFactory()
        return CashlyStore(
            initialState: .new(),
            reducer: AddUserReducer(),
            middleware: AddUserMiddleware(
                budgetUseCase: factory.budget,
                categoryUseCase: factory.category,
                transactionUseCase: factory.transaction,
                userUseCase: factory.user
            )
        )
    }

    private func makeAddCategoryStore() -> CashlyStore<AddCategoryState, AddCategoryAction> {
        let factory = TestFactory()
        return CashlyStore(
            initialState: .new(),
            reducer: AddCategoryReducer(),
            middleware: AddCategoryMiddleware(
                budgetUseCase: factory.budget,
                categoryUseCase: factory.category,
                transactionUseCase: factory.transaction,
                userUseCase: factory.user
            )
        )
    }

    private func makeAddTagStore() -> CashlyStore<AddTagState, AddTagAction> {
        let factory = TestFactory()
        return CashlyStore(
            initialState: .new(),
            reducer: AddTagReducer(),
            middleware: AddTagMiddleware(
                tagUseCase: factory.tag,
                userUseCase: factory.user
            )
        )
    }

    private func makeMainStore() -> CashlyStore<MainState, MainAction> {
        let factory = TestFactory()
        return CashlyStore(
            initialState: MainState(),
            reducer: MainReducer(),
            middleware: MainMiddleware(
                budgetUseCase: factory.budget,
                categoryUseCase: factory.category,
                transactionUseCase: factory.transaction,
                tagUseCase: factory.tag,
                userUseCase: factory.user
            )
        )
    }

    private struct TestFactory {
        let user = UserUseCaseDouble()
        let budget = BudgetUseCaseDouble()
        let category = CategoryUseCaseDouble()
        let transaction = TransactionUseCaseDouble()
        let tag = TagUseCaseDouble()
        let participant = ParticipantUseCaseDouble()
    }
}
