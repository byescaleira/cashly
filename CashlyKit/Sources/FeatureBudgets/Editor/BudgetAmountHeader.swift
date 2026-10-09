import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct BudgetAmountHeader: View {
    @Environment(BudgetEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        let color = Color(hex: model.draft.category?.color)
        Section {
        } header: {
            VStack(spacing: 0) {
                if let category = model.draft.category {
                    Text(category.name.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(color.opacity(0.2), in: .capsule)
                }
                CurrencyField(amount: $model.draft.amount)
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .tint(.clear)
            }
        }
    }
}
