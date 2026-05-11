//
//  MainReducerTests.swift
//  CashlyKit
//

import Testing
import CashlyDomain
import CashlyMock
@testable import CashlyPresentation

@MainActor
@Suite("MainReducer", .tags(.unit, .presentation, .local))
struct MainReducerTests {
    let reducer = MainReducer()

    @Test("fetch sets isLoading")
    func fetchSetsLoading() {
        var state = MainState(isLoading: false)
        _ = reducer.reduce(into: &state, action: .fetch)
        #expect(state.isLoading == true)
    }

    @Test("stopLoading clears loading")
    func stopLoadingClears() {
        var state = MainState(isLoading: true)
        _ = reducer.reduce(into: &state, action: .stopLoading)
        #expect(state.isLoading == false)
    }

    @Test("update populates everything")
    func updatePopulates() {
        var state = MainState()
        let budgets = Budget.mocks
        let categories: [CashlyDomain.Category] = CashlyDomain.Category.mocks
        let tags = Tag.mocks
        let users = User.mocks
        let user = users.first

        _ = reducer.reduce(into: &state, action: .update(
            filter: FilterState(),
            budgets: budgets,
            categories: categories,
            transactions: [],
            tags: tags,
            users: users,
            user: user,
            predictedTransactionsAmount: 42.5
        ))

        #expect(state.budgets == budgets)
        #expect(state.categories == categories)
        #expect(state.tags == tags)
        #expect(state.users == users)
        #expect(state.user == user)
        #expect(state.predictedTransactionsAmount == 42.5)
    }

    @Test("removeTag drops the tag from state.tags and from filter.tags")
    func removeTagDropsFromBoth() {
        let tags = Tag.mocks
        guard let dropped = tags.first else { return }
        var filter = FilterState()
        filter.tags = Set(tags)

        var state = MainState(filter: filter, tags: tags)
        _ = reducer.reduce(into: &state, action: .removeTag(dropped))

        #expect(state.tags.contains(where: { $0.id == dropped.id }) == false)
        #expect(state.filter.tags.contains(where: { $0.id == dropped.id }) == false)
    }

    @Test("removeTransaction drops by id")
    func removeTransactionDrops() {
        let transactions = CashlyDomain.Transaction.mocks
        guard let dropped = transactions.first else { return }
        var state = MainState(transactions: transactions)
        _ = reducer.reduce(into: &state, action: .removeTransaction(dropped))
        #expect(state.transactions.contains(where: { $0.id == dropped.id }) == false)
        #expect(state.transactions.count == transactions.count - 1)
    }

    @Test("removeTransactions drops the whole set")
    func removeTransactionsDropsSet() {
        let transactions = CashlyDomain.Transaction.mocks
        let dropped = Set(transactions.prefix(2))
        var state = MainState(transactions: transactions)
        _ = reducer.reduce(into: &state, action: .removeTransactions(dropped))
        for d in dropped {
            #expect(state.transactions.contains(where: { $0.id == d.id }) == false)
        }
    }

    @Test("error stores")
    func errorStores() {
        var state = MainState()
        _ = reducer.reduce(into: &state, action: .error(.persistence(.fetchFailed(entity: "Test", underlying: "boom"))))
        if case .persistence(.fetchFailed) = state.error {} else { Issue.record("expected .persistence(.fetchFailed)") }
    }

    @Test("replace swaps state")
    func replaceSwaps() {
        var state = MainState()
        let target = MainState(isLoading: false, predictedTransactionsAmount: 999)
        _ = reducer.reduce(into: &state, action: .replace(target))
        #expect(state.isLoading == false)
        #expect(state.predictedTransactionsAmount == 999)
    }

    @Test("selectUser is a no-op for reducer (middleware handles I/O)")
    func selectUserIsNoop() {
        var state = MainState()
        let before = state
        _ = reducer.reduce(into: &state, action: .selectUser)
        #expect(state.isLoading == before.isLoading)
        #expect(state.user == before.user)
    }

    @Test("fetchPredictions is a no-op for reducer")
    func fetchPredictionsIsNoop() {
        var state = MainState()
        let before = state
        _ = reducer.reduce(into: &state, action: .fetchPredictions)
        #expect(state.isLoading == before.isLoading)
        #expect(state.predictedTransactionsAmount == before.predictedTransactionsAmount)
    }
}
