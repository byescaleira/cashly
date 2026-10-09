import SwiftUI

public struct CurrencyField: View {
    @Binding private var amount: Double

    public init(amount: Binding<Double>) {
        _amount = amount
    }

    public var body: some View {
        TextField(
            "Valor",
            text: Binding(
                get: { amount.formatted(.appCurrency) },
                set: { amount = CurrencyInput.amount(typed: $0) })
        )
        #if os(iOS)
            .keyboardType(.numberPad)
        #endif
    }
}
