//
//  CashlySymbol.swift
//  CashlyKit
//
//  Wave 5b: Cashly-owned SF Symbol view. Wraps SwiftUI.Image with
//  symbol rendering mode + variants. Applies redacted skeleton when
//  `\.isLoading` is true.
//

import SwiftUI
import PrismUI

public struct CashlySymbol: View {
    @Environment(\.isLoading) private var isLoading

    private let name: String
    private let mode: SymbolRenderingMode
    private let variants: SymbolVariants

    public init(
        _ name: String = "infinity",
        mode: SymbolRenderingMode = .monochrome,
        variants: SymbolVariants = .none
    ) {
        self.name = name
        self.mode = mode
        self.variants = variants
    }

    public var body: some View {
        Image(systemName: name)
            .symbolRenderingMode(mode)
            .symbolVariant(variants)
            .redacted(reason: isLoading ? .placeholder : [])
    }
}
