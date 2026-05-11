//
//  Animation+ReduceMotion.swift
//  CashlyKit
//
//  //  helper that respects accessibilityReduceMotion env value.
//  Use `view.cashlyAnimation(.bouncy, value: x)` instead of `.animation(...)`
//  to disable motion when the user has the system flag on.
//

import SwiftUI

public extension View {
    /// Equivalent to `.animation(_:value:)` but returns `.none` when the
    /// user has Reduce Motion enabled.
    func cashlyAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        modifier(CashlyAnimationModifier(animation: animation, value: value))
    }
}

private struct CashlyAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}
