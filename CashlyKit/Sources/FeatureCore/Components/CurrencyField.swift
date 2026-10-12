import CashlyDesignSystem
import CashlyDomain
import SwiftUI

public struct CurrencyField: View {
    @Environment(\.appTint) private var appTint
    @Environment(\.multilineTextAlignment) private var textAlignment
    @Binding private var amount: Double
    @State private var digits = ""
    @FocusState private var isFocused: Bool

    public init(amount: Binding<Double>) {
        _amount = amount
    }

    public var body: some View {
        ZStack(alignment: alignment) {
            TextField("", text: $digits)
                #if os(iOS)
                    .keyboardType(.numberPad)
                #endif
                .focused($isFocused)
                .opacity(.opacityHidden)
                .accessibilityHidden(true)
            Text(amount.formatted(.appCurrency))
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
        .onAppear { digits = CurrencyInput.digits(for: amount) }
        .onChange(of: digits) { _, typed in
            let clean = CurrencyInput.clean(typed)
            if clean != typed { digits = clean }
            let value = CurrencyInput.amount(typed: clean)
            if value != amount { amount = value }
        }
        .onChange(of: amount) { _, value in
            if CurrencyInput.amount(typed: digits) != value {
                digits = CurrencyInput.digits(for: value)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Valor")
        .accessibilityValue(amount.formatted(.appCurrency))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { isFocused = true }
    }

    private var alignment: Alignment {
        switch textAlignment {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
}
