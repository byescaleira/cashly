//
//  CashlyButton.swift
//  CashlyKit
//
//  //  Cashly-owned button. Wraps SwiftUI.Button. Async action
//  is wrapped in Task. Light haptic feedback on iOS.
//

import SwiftUI

public struct CashlyButton<Label: View>: View {
    private let role: ButtonRole?
    private let action: () async -> Void
    private let label: Label

    public init(
        role: ButtonRole? = nil,
        action: @escaping () async -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.role = role
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(role: role) {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            Task { await action() }
        } label: {
            label
        }
    }
}
