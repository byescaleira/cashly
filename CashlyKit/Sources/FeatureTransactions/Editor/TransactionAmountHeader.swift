import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct TransactionAmountHeader: View {
    @Environment(TransactionEditorModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var model = model
        Section {
        } header: {
            VStack(spacing: .spaceS) {
                if !model.draft.participants.isEmpty {
                    Pill(
                        model.draft.splitValue?.formatted(.appCurrency) ?? "",
                        color: model.splitStatus.color
                    )
                    .font(.headline.weight(.semibold))
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .linear, value: model.draft.splitValue)
                    .background(model.splitStatus.color.opacity(.opacityTint), in: .capsule)
                }
                VStack(spacing: 0) {
                    CurrencyField(amount: $model.amountInput, currencyCode: model.inputCurrency)
                        .font(.amountInput)
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.center)
                        .tint(.clear)
                        .disabled(model.isAmountLocked)
                    if let real = model.realAmount {
                        Text(verbatim: real)
                            .font(.headline)
                            .foregroundStyle(Color.secondary)
                            .contentTransition(.numericText())
                            .animation(reduceMotion ? nil : .snappy, value: model.draft.amount)
                            .amountLine()
                    }
                    if let installments = model.installmentDescription {
                        Text(installments)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(Color.secondary)
                            .contentTransition(.numericText())
                            .animation(reduceMotion ? nil : .bouncy, value: model.draft.amount)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spaceS)
        }
    }
}

private struct Pill: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .foregroundStyle(color)
            .padding(.vertical, .spaceS)
            .padding(.horizontal, .spaceM)
    }
}
