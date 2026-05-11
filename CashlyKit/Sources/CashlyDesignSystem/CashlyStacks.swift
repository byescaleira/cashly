//
//  CashlyStacks.swift
//  CashlyKit
//
//  Wave 5b: Cashly-owned HStack/VStack/ZStack. Thin SwiftUI wrappers
//  taking CashlySpacing for spacing.
//

import SwiftUI

public struct CashlyHStack<Content: View>: View {
    private let alignment: VerticalAlignment
    private let spacing: CashlySpacing?
    private let content: Content

    public init(
        alignment: VerticalAlignment = .center,
        spacing: CashlySpacing? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        HStack(alignment: alignment, spacing: spacing?.rawValue) {
            content
        }
    }
}

public struct CashlyVStack<Content: View>: View {
    private let alignment: HorizontalAlignment
    private let spacing: CashlySpacing?
    private let content: Content

    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CashlySpacing? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: alignment, spacing: spacing?.rawValue) {
            content
        }
    }
}

public struct CashlyZStack<Content: View>: View {
    private let alignment: Alignment
    private let content: Content

    public init(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.content = content()
    }

    public var body: some View {
        ZStack(alignment: alignment) {
            content
        }
    }
}
