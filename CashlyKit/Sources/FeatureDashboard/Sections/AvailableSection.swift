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
                    Menu {
                        Picker(selection: $dashboard.availableCategory) {
                            ForEach(finance.categories) { Text($0.name).tag(Optional($0)) }
                        } label: {
                            EmptyView()
                        }
                    } label: {
                        HStack(spacing: 16) {
                            Text("Categoria").font(.body).foregroundStyle(Color.primary)
                            Spacer()
                            HStack {
                                Text(category.name.capitalized).font(.body.weight(.semibold))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.footnote.weight(.semibold))
                            }
                            .foregroundStyle(Color.accentColor)
                        }
                    }
                    HStack(spacing: 8) {
                        Text(availability.available.formatted(.brl)).font(.title3.weight(.bold))
                        Text("/  \(availability.budgeted.formatted(.brl))")
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                            .padding(.bottom, -4)
                        Spacer()
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
                        Text(dashboard.totalAvailable.formatted(.brl))
                            .font(.largeTitle.weight(.black))
                            .foregroundStyle(Color.primary)
                        Text(finance.budgetsAmount.formatted(.brl))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            }
        }
    }
}
