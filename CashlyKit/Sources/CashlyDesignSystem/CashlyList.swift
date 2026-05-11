//
//  CashlyList.swift
//  CashlyKit
//
//  //  Cashly-owned list. Wraps SwiftUI.List with optional selection
//  binding.
//

import SwiftUI

public struct CashlyList<SelectionValue: Hashable, Content: View>: View {
    private let selection: Binding<Set<SelectionValue>>?
    private let content: Content

    public init(
        selection: Binding<Set<SelectionValue>>? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.selection = selection
        self.content = content()
    }

    public var body: some View {
        List(selection: selection) {
            content
        }
    }
}

public extension CashlyList where SelectionValue == Never {
    init(@ViewBuilder content: () -> Content) {
        self.selection = nil
        self.content = content()
    }
}
