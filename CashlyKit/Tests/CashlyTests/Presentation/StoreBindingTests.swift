//
//  StoreBindingTests.swift
//  CashlyKit
//
//  cashlyBinding / cashlyMutate / cashlyReplace funnel writes through
//  Action.replace(State). Tests assert that the state-after-write
//  matches a State whose only mutation was the targeted field.
//

import Foundation
import Testing
import CashlyDomain
@testable import CashlyPresentation

@MainActor
@Suite("Store binding helpers", .tags(.unit, .presentation, .local))
struct StoreBindingTests {

    private func makeStore() -> CashlyStore<AddUserState, AddUserAction> {
        CashlyStore(
            initialState: .new(),
            reducer: AddUserReducer()
        )
    }

    @Test("cashlyBinding(get) returns the current key path value")
    func bindingGetReturnsCurrent() {
        let store = makeStore()
        let binding = store.cashlyBinding(\.name)
        #expect(binding.wrappedValue == store.state.name)
    }

    @Test("cashlyBinding(set) propagates the write through .replace")
    func bindingSetWritesViaReplace() async {
        let store = makeStore()
        let binding = store.cashlyBinding(\.name)
        binding.wrappedValue = "Alice"
        // give the store a tick for `send` → reduce(into:) to settle
        await Task.yield()
        #expect(store.state.name == "Alice")
    }

    @Test("cashlyMutate writes the field via .replace")
    func mutateWritesField() async {
        let store = makeStore()
        store.cashlyMutate(\.photo, "https://x/a.png")
        await Task.yield()
        #expect(store.state.photo == "https://x/a.png")
    }

    @Test("cashlyReplace swaps the whole state via .replace")
    func replaceSwapsWholeState() async {
        let store = makeStore()
        let target = AddUserState.edit(id: "edited")
        store.cashlyReplace(target)
        await Task.yield()
        #expect(store.state.id == "edited")
        #expect(store.state.isNew == false)
    }

    @Test("nested-key-path bindings round-trip through dynamic-member projection")
    func nestedBindingsRoundtrip() async {
        // MainState carries a FilterState with isFilteringByDate; the
        // composite keypath `\.filter.isFilteringByDate` is exactly what
        // FilterItemView's Toggle uses.
        let store = CashlyStore(
            initialState: MainState(),
            reducer: MainReducer()
        )
        let binding = store.cashlyBinding(\.filter)
        binding.isFilteringByDate.wrappedValue = false
        await Task.yield()
        #expect(store.state.filter.isFilteringByDate == false)
    }
}
