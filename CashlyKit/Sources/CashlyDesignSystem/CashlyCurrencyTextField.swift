//
//  CashlyCurrencyTextField.swift
//  CashlyKit
//
//  Currency-masked text field built on SwiftUI.TextField + Foundation
//  NumberFormatter. Two-way binding maintains a digits-only mental
//  model: typed digits accumulate into `amount`; the displayed text
//  is reformatted on every change.
//

import SwiftUI

public struct CashlyCurrencyTextField: View {
    @Binding private var amount: Double
    @State private var text: String = ""
    private let locale: Locale

    public init(amount: Binding<Double>, locale: Locale = .current) {
        self._amount = amount
        self.locale = locale
    }

    public var body: some View {
        TextField("", text: $text)
            .foregroundStyle(amount == .zero ? Color.secondary : Color.primary)
            #if os(iOS)
            .keyboardType(.numberPad)
            #endif
            .onAppear {
                if text.isEmpty { text = Self.format(amount, locale: locale) }
            }
            .onChange(of: amount) { _, newValue in
                let formatted = Self.format(newValue, locale: locale)
                if formatted != text { text = formatted }
            }
            .onChange(of: text) { _, newValue in
                let digits = newValue.compactMap(\.wholeNumberValue)
                let value = digits.reduce(0) { $0 * 10 + Double($1) } / 100
                if value != amount { amount = value }
                let masked = Self.format(value, locale: locale)
                if masked != newValue { text = masked }
            }
    }

    private static func format(_ value: Double, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
}
