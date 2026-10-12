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
                        .font(.chipLabel)
                        .foregroundStyle(color)
                        .padding(.vertical, .spaceS)
                        .padding(.horizontal, .spaceM)
                        .background(color.opacity(.opacityTint), in: .capsule)
                }
                CurrencyField(amount: $model.draft.amount)
                    .font(.amountInput)
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, .spaceL)
                    .tint(.clear)
            }
        }
    }
}
