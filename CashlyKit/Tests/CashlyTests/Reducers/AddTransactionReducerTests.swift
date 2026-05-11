//
//  AddTransactionReducerTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock
@testable import CashlyPresentation

@MainActor
@Suite("AddTransactionReducer", .tags(.unit, .presentation, .local))
struct AddTransactionReducerTests {
    let reducer = AddTransactionReducer()

    @Test("fetch sets isLoading=true")
    func fetchSetsLoading() {
        var state = AddTransactionState.new()
        state.isLoading = false
        _ = reducer.reduce(into: &state, action: .fetch)
        #expect(state.isLoading == true)
    }

    @Test("stopLoading clears loading")
    func stopLoadingClears() {
        var state = AddTransactionState.new()
        state.isLoading = true
        _ = reducer.reduce(into: &state, action: .stopLoading)
        #expect(state.isLoading == false)
    }

    @Test("update populates 14-field payload")
    func updatePopulates() {
        var state = AddTransactionState.new()
        let budgets = Budget.mocks
        let budget = budgets.first
        let participants = Participant.mocks
        let tags = Tag.mocks
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        _ = reducer.reduce(into: &state, action: .update(
            budgets: budgets,
            id: "tx-1",
            participants: participants,
            budget: budget,
            amount: 123.45,
            date: date,
            summary: "Dinner",
            status: .pendingToPay,
            splitMode: .equal,
            splitValue: 7.5,
            tags: tags,
            isNew: false,
            installmentIsOn: true,
            installmentPlan: 6
        ))

        #expect(state.budgets == budgets)
        #expect(state.id == "tx-1")
        #expect(state.participants == participants)
        #expect(state.budget == budget)
        #expect(state.amount == 123.45)
        #expect(state.date == date)
        #expect(state.summary == "Dinner")
        #expect(state.status == .pendingToPay)
        #expect(state.splitMode == .equal)
        #expect(state.splitValue == 7.5)
        #expect(state.tags == tags)
        #expect(state.isNew == false)
        #expect(state.installmentIsOn == true)
        #expect(state.installmentPlan == 6)
    }

    @Test("saved flips isSaved")
    func savedFlipsFlag() {
        var state = AddTransactionState.new()
        _ = reducer.reduce(into: &state, action: .saved)
        #expect(state.isSaved == true)
    }

    @Test("error stores error")
    func errorStores() {
        var state = AddTransactionState.new()
        _ = reducer.reduce(into: &state, action: .error(.persistence(.removeFailed(entity: "Test", underlying: "boom"))))
        if case .persistence(.removeFailed) = state.error {} else { Issue.record("expected .persistence(.removeFailed)") }
    }

    @Test("replace swaps state")
    func replaceSwaps() {
        var state = AddTransactionState.new()
        let target = AddTransactionState.edit(id: "tx-swap")
        _ = reducer.reduce(into: &state, action: .replace(target))
        #expect(state.id == "tx-swap")
        #expect(state.isNew == false)
    }
}
