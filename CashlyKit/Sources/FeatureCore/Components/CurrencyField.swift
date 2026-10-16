import CashlyDesignSystem
import CashlyDomain
import SwiftUI

public struct CurrencyField: View {
    @Environment(\.appTint) private var appTint
    @Environment(\.multilineTextAlignment) private var textAlignment
    @Binding private var amount: Double
    private let currencyCode: String
    @State private var digits = ""
    @State private var selection: TextSelection?
    @FocusState private var isFocused: Bool

    public init(amount: Binding<Double>, currencyCode: String = Money.currencyCode) {
        _amount = amount
        self.currencyCode = currencyCode
    }

    public var body: some View {
        ZStack(alignment: alignment) {
            TextField("Amount", text: $digits, selection: $selection)
                #if os(iOS)
                    .keyboardType(.numberPad)
                #endif
                .focused($isFocused)
                .opacity(.opacityHidden)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            Text(
                amount.formatted(
                    .currency(code: currencyCode).precision(.fractionLength(fractionDigits)).locale(
                        .app))
            )
            .contentTransition(.numericText(value: amount))
            .animation(.snappy, value: amount)
            .overlay(alignment: .bottom) {
                Capsule()
                    .frame(height: 3)
                    .foregroundStyle(appTint)
                    .offset(y: 6)
                    .opacity(isFocused ? 1 : 0)
            }
            .allowsHitTesting(false)
        }
        .contentShape(.rect)
        .onTapGesture { isFocused = true }
        .onAppear { digits = CurrencyInput.digits(for: amount, fractionDigits: fractionDigits) }
        .onChange(of: digits) { _, typed in
            let clean = CurrencyInput.clean(typed)
            if clean != typed { digits = clean }
            let value = CurrencyInput.amount(typed: clean, fractionDigits: fractionDigits)
            if value != amount { amount = value }
            pinCaret()
        }
        .onChange(of: selection) { pinCaret() }
        .onChange(of: currencyCode) {
            digits = CurrencyInput.digits(for: amount, fractionDigits: fractionDigits)
        }
        .onChange(of: amount) { _, value in
            if CurrencyInput.amount(typed: digits, fractionDigits: fractionDigits) != value {
                digits = CurrencyInput.digits(for: value, fractionDigits: fractionDigits)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Amount")
        .accessibilityValue(amount.formatted(.currency(code: currencyCode).locale(.app)))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { isFocused = true }
    }

    private var fractionDigits: Int { CurrencyInput.fractionDigits(for: currencyCode) }

    private func pinCaret() {
        let end = TextSelection(insertionPoint: digits.endIndex)
        if selection != end { selection = end }
    }

    private var alignment: Alignment {
        switch textAlignment {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
}
