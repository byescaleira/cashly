import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct AvailableSection: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(DashboardModel.self) private var dashboard

    var body: some View {
        if finance.budgetsAmount > 0 {
            let usage = dashboard.totalUsage
            Section {
                VStack(spacing: .space2XS) {
                    Text("\(finance.budgetsAmount.formatted(.appCurrency)) planejado")
                        .font(.headline)
                        .amountLine()
                    Text(
                        "\(usage.ratio.formatted(.percent.precision(.fractionLength(0)))) usado · \(usage.stage.title)"
                    )
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(usage.stage.color)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .space2XS)
            } header: {
                FigureHeader(
                    title: "Disponível", value: dashboard.totalAvailable,
                    color: dashboard.totalAvailable < 0 ? .negative : .primary
                ) {
                    EmptyView()
                }
            }
        }
    }
}
