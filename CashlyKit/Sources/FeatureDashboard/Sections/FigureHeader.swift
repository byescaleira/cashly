import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct FigureHeader<Detail: View>: View {
    let title: LocalizedStringKey
    let value: Double
    var color: Color = .primary
    @ViewBuilder let detail: () -> Detail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).sectionTitle().frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 6) {
                Text(value.formatted(.appCurrency))
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(color)
                    .contentTransition(.numericText(value: value))
                    .amountLine()
                detail()
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
}
