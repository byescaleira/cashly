//
//  AddUserReducerTests.swift
//  CashlyKit
//
//  Unit tests for AddUserReducer — pure @MainActor function on State.
//

import Testing
import CashlyDomain
@testable import CashlyPresentation

@MainActor
@Suite("AddUserReducer", .tags(.unit, .presentation, .local))
struct AddUserReducerTests {
    let reducer = AddUserReducer()

    @Test("fetch sets isLoading=true")
    func fetchSetsLoading() {
        var state = AddUserState.new()
        state.isLoading = false
        _ = reducer.reduce(into: &state, action: .fetch)
        #expect(state.isLoading == true)
    }

    @Test("stopLoading sets isLoading=false")
    func stopLoadingClearsLoading() {
        var state = AddUserState.new()
        state.isLoading = true
        _ = reducer.reduce(into: &state, action: .stopLoading)
        #expect(state.isLoading == false)
    }

    @Test("update populates fields")
    func updatePopulatesFields() {
        var state = AddUserState.new()
        _ = reducer.reduce(into: &state, action: .update(
            id: "user-1",
            name: "Alice",
            photo: "https://example.com/alice.png",
            isNew: false
        ))
        #expect(state.id == "user-1")
        #expect(state.name == "Alice")
        #expect(state.photo == "https://example.com/alice.png")
        #expect(state.isNew == false)
    }

    @Test("saved sets isSaved=true")
    func savedFlipsFlag() {
        var state = AddUserState.new()
        #expect(state.isSaved == false)
        _ = reducer.reduce(into: &state, action: .saved)
        #expect(state.isSaved == true)
    }

    @Test("error stores CashlyError")
    func errorStoresError() {
        var state = AddUserState.new()
        _ = reducer.reduce(into: &state, action: .error(.onSave))
        #expect(state.error == .onSave)
    }

    @Test("replace swaps entire state")
    func replaceReplacesState() {
        var state = AddUserState.new()
        let target = AddUserState.edit(id: "different-id")
        _ = reducer.reduce(into: &state, action: .replace(target))
        #expect(state.id == "different-id")
        #expect(state.isNew == false)
    }

    @Test("save action is a no-op for reducer (middleware handles I/O)")
    func saveIsNoop() {
        var state = AddUserState.new()
        let before = state
        _ = reducer.reduce(into: &state, action: .save)
        #expect(state.id == before.id)
        #expect(state.name == before.name)
        #expect(state.isLoading == before.isLoading)
        #expect(state.isSaved == before.isSaved)
    }

    @Test("remove action is a no-op for reducer")
    func removeIsNoop() {
        var state = AddUserState.new()
        let before = state
        _ = reducer.reduce(into: &state, action: .remove)
        #expect(state.id == before.id)
        #expect(state.isLoading == before.isLoading)
    }
}
