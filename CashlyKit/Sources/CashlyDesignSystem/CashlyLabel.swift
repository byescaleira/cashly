//
//  CashlyLabel.swift
//  CashlyKit
//
//  //  Cashly-owned label. SwiftUI.Label + isLoading skeleton.
//

import SwiftUI

public struct CashlyLabel: View {
    @Environment(\.isLoading) private var isLoading

    private let text: String?
    private let symbol: String

    public init(_ text: String?, symbol: String) {
        self.text = text
        self.symbol = symbol
    }

    @ViewBuilder
    public var body: some View {
        if isLoading {
            Label(text ?? CashlyText.placeholder, systemImage: symbol)
                .redacted(reason: .placeholder)
        } else if let text {
            Label(text, systemImage: symbol)
        }
    }
}
