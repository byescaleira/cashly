//
//  Store+Binding.swift
//  CashlyKit
//
//  Wave 5a': intermediate binding helper that bridges Cashly screens to
//  CashlyStore without the call sites depending on `state` being a
//  settable property on the store. The previous `@Bindable var store;
//  binding-to-state-field` pattern compiles today against Ryze (state
//  is `var`) but breaks against PrismStore (state is `private(set)`).
//
//  By routing all writable bindings through `store.cashlyBinding(...)`,
//  the Wave 5a Package.swift swap to Prism becomes mechanical: this file
//  is the one place that changes — set the closure to call
//  `send(.updateX($0))` (action-based) or `store.scope(...)` (child
//  store) instead of writing `state[keyPath:] = $0`.
//

import SwiftUI
import RyzeArchitecture

public extension RyzeStore {
    /// Two-way binding into a writable key path of the store's State.
    ///
    /// Today (Ryze): writes go straight to `state[keyPath:]` because
    /// RyzeStore.state is publicly settable.
    /// Tomorrow (Prism): this single function gets rewritten to dispatch
    /// an action or open a scoped child store; all call sites stay put.
    @MainActor
    func cashlyBinding<Value>(_ keyPath: WritableKeyPath<Reducer.State, Value>) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.state[keyPath: keyPath] = $0 }
        )
    }

    /// One-shot state mutation seam. Today writes directly into
    /// `state[keyPath:]`; after the Prism swap, gets rewritten to a
    /// dispatched action without touching any call site.
    @MainActor
    func cashlyMutate<Value>(_ keyPath: WritableKeyPath<Reducer.State, Value>, _ newValue: Value) {
        self.state[keyPath: keyPath] = newValue
    }

    /// Whole-state replacement seam (initial-state hydration only).
    @MainActor
    func cashlyReplace(_ newState: Reducer.State) {
        self.state = newState
    }
}
