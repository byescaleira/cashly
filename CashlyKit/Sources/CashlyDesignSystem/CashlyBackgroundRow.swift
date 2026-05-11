//
//  CashlyBackgroundRow.swift
//  CashlyKit
//
//  List-row background that adapts to colorScheme: secondary system
//  background in dark mode, primary in light.
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
