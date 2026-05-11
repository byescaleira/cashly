//
//  CashlyBackgroundRow.swift
//  CashlyKit
//
//  Wave 5a'': Cashly-owned list-row background. Mirrors Ryze behavior of
//  using the secondary system background in dark mode and the primary
//  system background in light mode.
//

import SwiftUI

public struct CashlyBackgroundRowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public func body(content: Content) -> some View {
        content.background(background)
    }

    private var background: Color {
        #if canImport(UIKit)
        colorScheme == .dark
            ? Color(UIColor.secondarySystemBackground)
            : Color(UIColor.systemBackground)
        #else
        colorScheme == .dark
            ? Color(NSColor.underPageBackgroundColor)
            : Color(NSColor.windowBackgroundColor)
        #endif
    }
}
