//
//  CashlyReplaceableAction.swift
//  CashlyKit
//
//  Wave 5a: protocol for Actions that expose a `.replace(State)` case
//  used by Store+Binding helpers (cashlyBinding / cashlyMutate /
//  cashlyReplace). PrismStore.state is `private(set)`, so all writes
//  flow through this single action case + its reducer arm.
//

public protocol CashlyReplaceableAction: Sendable {
    associatedtype State: Sendable
    static func replace(_ state: State) -> Self
}
