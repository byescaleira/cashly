//
//  AddCategoryReducerTests.swift
//  CashlyKit
//

import Testing
import CashlyDomain
import CashlyMock
@testable import CashlyPresentation

@MainActor
@Suite("AddCategoryReducer", .tags(.unit, .presentation, .local))
struct AddCategoryReducerTests {
    let reducer = AddCategoryReducer()

    @Test("fetch sets isLoading=true")
    func fetchSetsLoading() {
        var state = AddCategoryState.new()
        state.isLoading = false
        _ = reducer.reduce(into: &state, action: .fetch)
        #expect(state.isLoading == true)
    }

    @Test("stopLoading clears loading")
    func stopLoadingClears() {
        var state = AddCategoryState.new()
        state.isLoading = true
        _ = reducer.reduce(into: &state, action: .stopLoading)
        #expect(state.isLoading == false)
    }

    @Test("update populates id/user/name/color/icon/isNew")
    func updatePopulates() {
        var state = AddCategoryState.new()
        let user = User.mock
        _ = reducer.reduce(into: &state, action: .update(
            id: "cat-1",
            user: user,
            name: "Food",
            color: "#FF0000",
            icon: "fork.knife",
            isNew: false
        ))
        #expect(state.id == "cat-1")
        #expect(state.user == user)
        #expect(state.name == "Food")
        #expect(state.color == "#FF0000")
        #expect(state.icon == "fork.knife")
        #expect(state.isNew == false)
    }

    @Test("saved flips isSaved")
    func savedFlipsFlag() {
        var state = AddCategoryState.new()
        _ = reducer.reduce(into: &state, action: .saved)
        #expect(state.isSaved == true)
    }

    @Test("error stores error")
    func errorStores() {
        var state = AddCategoryState.new()
        _ = reducer.reduce(into: &state, action: .error(.onFetch))
        #expect(state.error == .onFetch)
    }

    @Test("replace swaps state")
    func replaceSwaps() {
        var state = AddCategoryState.new()
        let target = AddCategoryState.edit(id: "swap")
        _ = reducer.reduce(into: &state, action: .replace(target))
        #expect(state.id == "swap")
        #expect(state.isNew == false)
    }
}
