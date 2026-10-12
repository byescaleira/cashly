import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct BudgetsOverviewSection: View {
    @Environment(GoalsModel.self) private var goals
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(\.appTint) private var appTint
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        let overview = goals.overview
        if !finance.categories.isEmpty {
            Section {
                if overview.items.isEmpty {
                    Button {
                        open(
                            .addBudget(id: nil, categoryID: nil, date: session.filter.startDate),
                            in: section)
                    } label: {
                        Label("Create Budget", systemImage: "plus.circle.fill")
                            .font(.buttonLabel)
                    }
                } else {
                    Button {
                        open(.budgets, in: section)
                    } label: {
                        BudgetsOverviewCard(overview: overview, showsAmount: true)
                    }
                    .buttonStyle(.plain)
                    Button {
                        open(.budgets, in: section)
                    } label: {
                        HStack(spacing: .spaceM) {
                            Text(overview.linkTitle)
                                .font(.buttonLabel)
                                .foregroundStyle(appTint)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.forward")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Budgets").sectionTitle()
            } footer: {
                if overview.items.isEmpty {
                    Text("Set how much you want to spend in each category this month.")
                } else if let daily = overview.dailyAllowance, let days = overview.daysLeft {
                    Text(
                        "You can spend \(daily.formatted(.appCurrency)) per day over the next \(days) days."
                    )
                }
            }
        }
    }
}

struct BudgetsOverviewHeader: View {
    let title: LocalizedStringKey
    let overview: BudgetOverview

    var body: some View {
        FigureHeader(title: title, amount: overview.remainingAmount, color: overview.amountColor) {
            VStack(spacing: .space2XS) {
                Text(overview.headline)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .amountLine()
                Text(overview.usageTitle)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(overview.usageColor)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct BudgetsOverviewCard: View {
    let overview: BudgetOverview
    var showsAmount = false

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceM) {
            if showsAmount {
                HStack(alignment: .firstTextBaseline, spacing: .spaceS) {
                    VStack(alignment: .leading, spacing: .spaceHairline) {
                        Text(overview.remainingAmount.formatted(.appCurrency))
                            .font(.amountRow)
                            .foregroundStyle(overview.amountColor)
                            .contentTransition(.numericText(value: overview.remainingAmount))
                            .amountLine()
                        Text(overview.headline)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Chip(
                        overview.usageTitle.uppercased(), color: overview.usageColor,
                        shape: .capsule)
                }
            }
            ProgressView(value: min(overview.ratio, 1))
                .tint(overview.usageColor)
                .animation(.smooth, value: overview.ratio)
            FlowLayout(spacing: .spaceS) {
                ForEach(overview.counts, id: \.group) { entry in
                    Chip(entry.group.summary(count: entry.count), color: entry.group.color)
                }
            }
        }
        .padding(.vertical, .spaceXS)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

extension BudgetOverview {
    var amountColor: Color { remaining >= 0 ? .primary : .negative }
    var usageColor: Color { ratio > 1 ? .negative : ratio >= 0.8 ? .warning : .positive }
}
