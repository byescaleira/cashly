//
//  Store+Binding.swift
//  CashlyKit
//
//  //  PrismStore.state is `private(set)`. All writes from views
//  funnel through `Action.replace(State)` dispatched via `send(_:)`.
//  This file is the only thing that changed when the Package.swift swap
//  to Prism landed.
//

import SwiftUI
import PrismArchitecture

public extension PrismStore where Action: CashlyReplaceableAction, Action.State == State {
    /// Two-way binding into a writable key path of the store's State.
    /// Writes synthesize a new State and dispatch `.replace(newState)`.
    @MainActor
    func cashlyBinding<Value>(_ keyPath: WritableKeyPath<State, Value>) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { newValue in
                var current = self.state
                current[keyPath: keyPath] = newValue
                self.send(.replace(current))
            }
        )
    }

    /// One-shot field write. Dispatches `.replace(newState)` with the
    /// updated copy.
    @MainActor
    func cashlyMutate<Value>(_ keyPath: WritableKeyPath<State, Value>, _ newValue: Value) {
        var current = state
        current[keyPath: keyPath] = newValue
        send(.replace(current))
    }

    /// Whole-state replacement seam (initial-state hydration).
    @MainActor
    func cashlyReplace(_ newState: State) {
        send(.replace(newState))
    }
}
