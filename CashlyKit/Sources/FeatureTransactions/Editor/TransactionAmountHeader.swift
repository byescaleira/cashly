import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct TransactionAmountHeader: View {
    @Environment(TransactionEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
        } header: {
            VStack(spacing: 8) {
                if !model.draft.participants.isEmpty {
                    Pill(
                        model.draft.splitValue?.formatted(.appCurrency) ?? "",
                        color: model.splitStatus.color
                    )
                    .font(.headline.weight(.semibold))
                    .contentTransition(.numericText())
                    .animation(.linear, value: model.draft.splitValue)
                    .background(model.splitStatus.color.opacity(0.2), in: .capsule)
                }
                VStack(spacing: 0) {
                    CurrencyField(amount: $model.draft.amount)
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.center)
                        .tint(.clear)
                    if let installments = model.installmentDescription {
                        Text(installments)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(Color.secondary)
                            .contentTransition(.numericText())
                            .animation(.bouncy, value: model.draft.amount)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
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
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
    }
}
