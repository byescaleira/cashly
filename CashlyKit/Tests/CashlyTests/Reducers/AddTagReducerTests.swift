//
//  AddTagReducerTests.swift
//  CashlyKit
//

import Testing
import CashlyDomain
import CashlyMock
@testable import CashlyPresentation

@MainActor
@Suite("AddTagReducer", .tags(.unit, .presentation, .local))
struct AddTagReducerTests {
    let reducer = AddTagReducer()

    @Test("fetch sets isLoading=true")
    func fetchSetsLoading() {
        var state = AddTagState.new()
        state.isLoading = false
        _ = reducer.reduce(into: &state, action: .fetch)
        #expect(state.isLoading == true)
    }

    @Test("stopLoading clears loading")
    func stopLoadingClears() {
        var state = AddTagState.new()
        state.isLoading = true
        _ = reducer.reduce(into: &state, action: .stopLoading)
        #expect(state.isLoading == false)
    }

    @Test("update populates id/user/name/color/icon/isNew")
    func updatePopulates() {
        var state = AddTagState.new()
        let user = User.mock
        _ = reducer.reduce(into: &state, action: .update(
            id: "tag-1",
            user: user,
            name: "Coffee",
            color: "#8B4513",
            icon: "cup.and.saucer",
            isNew: true
        ))
        #expect(state.id == "tag-1")
        #expect(state.user == user)
        #expect(state.name == "Coffee")
        #expect(state.color == "#8B4513")
        #expect(state.icon == "cup.and.saucer")
        #expect(state.isNew == true)
    }

    @Test("saved flips isSaved")
    func savedFlipsFlag() {
        var state = AddTagState.new()
        _ = reducer.reduce(into: &state, action: .saved)
        #expect(state.isSaved == true)
    }

    @Test("error stores error")
    func errorStores() {
        var state = AddTagState.new()
        _ = reducer.reduce(into: &state, action: .error(.onRemove))
        #expect(state.error == .onRemove)
    }

    @Test("replace swaps state")
    func replaceSwaps() {
        var state = AddTagState.new()
        let target = AddTagState.edit(id: "tag-swap")
        _ = reducer.reduce(into: &state, action: .replace(target))
        #expect(state.id == "tag-swap")
    }
}
