import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct AvailableSection: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(DashboardModel.self) private var dashboard

    var body: some View {
        @Bindable var dashboard = dashboard
        if !finance.budgets.isEmpty {
            Section {
                if let category = dashboard.availableCategory {
                    let availability = dashboard.availability(of: category)
                    Picker("Categoria", selection: $dashboard.availableCategory) {
                        ForEach(finance.categories) { Text($0.name.capitalized).tag(Optional($0)) }
                    }
                    AdaptiveStack(spacing: 8) {
                        AdaptiveStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(availability.available.formatted(.appCurrency))
                                .font(.title3.weight(.bold))
                                .amountLine()
                            Text("de \(availability.budgeted.formatted(.appCurrency))")
                                .font(.footnote)
                                .foregroundStyle(Color.secondary)
                                .amountLine()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text(
                            availability.remainingRatio.formatted(
                                .percent.precision(.fractionLength(0)))
                        )
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(availability.usage.stage.color)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(availability.usage.stage.color.opacity(0.2), in: .capsule)
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Disponível").sectionTitle().frame(
                        maxWidth: .infinity, alignment: .leading)
                    VStack(spacing: 4) {
                        Text(dashboard.totalAvailable.formatted(.appCurrency))
                            .font(.largeTitle.weight(.black))
                            .foregroundStyle(Color.primary)
                            .amountLine()
                        Text(finance.budgetsAmount.formatted(.appCurrency))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                            .amountLine()
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            }
        }
    }
}
