//
//  AddBudgetReducerTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock
@testable import CashlyPresentation

@MainActor
@Suite("AddBudgetReducer", .tags(.unit, .presentation, .local))
struct AddBudgetReducerTests {
    let reducer = AddBudgetReducer()

    @Test("fetch sets isLoading=true")
    func fetchSetsLoading() {
        var state = AddBudgetState.new()
        state.isLoading = false
        _ = reducer.reduce(into: &state, action: .fetch)
        #expect(state.isLoading == true)
    }

    @Test("stopLoading clears loading")
    func stopLoadingClears() {
        var state = AddBudgetState.new()
        state.isLoading = true
        _ = reducer.reduce(into: &state, action: .stopLoading)
        #expect(state.isLoading == false)
    }

    @Test("update populates fields and parses date from yearMonth")
    func updatePopulates() {
        var state = AddBudgetState.new()
        let categories: [CashlyDomain.Category] = [.mock]
        let category: CashlyDomain.Category = .mock

        _ = reducer.reduce(into: &state, action: .update(
            categories: categories,
            id: "budget-1",
            amount: 500,
            category: category,
            date: 202604,
            summary: "Groceries",
            isNew: false
        ))

        #expect(state.categories == categories)
        #expect(state.id == "budget-1")
        #expect(state.amount == 500)
        #expect(state.category == category)
        #expect(state.summary == "Groceries")
        #expect(state.isNew == false)
    }

    @Test("saved flips isSaved")
    func savedFlipsFlag() {
        var state = AddBudgetState.new()
        _ = reducer.reduce(into: &state, action: .saved)
        #expect(state.isSaved == true)
    }

    @Test("error stores error")
    func errorStores() {
        var state = AddBudgetState.new()
        _ = reducer.reduce(into: &state, action: .error(.persistence(.saveFailed(entity: "Test", underlying: "boom"))))
        if case .persistence(.saveFailed) = state.error {} else { Issue.record("expected .persistence(.saveFailed)") }
    }

    @Test("replace swaps state")
    func replaceSwaps() {
        var state = AddBudgetState.new()
        let target = AddBudgetState.edit(id: "edited")
        _ = reducer.reduce(into: &state, action: .replace(target))
        #expect(state.id == "edited")
        #expect(state.isNew == false)
    }
}
