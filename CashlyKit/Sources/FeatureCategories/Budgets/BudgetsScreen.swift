import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct BudgetsScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(GoalsModel.self) private var goals
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    public init() {}

    public var body: some View {
        @Bindable var goals = goals
        AdaptiveList {
            BudgetsSummarySection()
            ForEach(goals.overview.groups, id: \.group) { entry in
                BudgetGroupSection(group: entry.group, items: entry.items)
            }
            UnbudgetedSection()
        }
        .emptyState(.budget, when: goals.overview.items.isEmpty && !finance.isLoading)
        .fontDesign(.rounded)
        .toolbar {
            ToolbarItem { FilterMenu() }
            FixedToolbarSpacer()
            ToolbarItem {
                Button("New Budget", systemImage: "plus") {
                    open(
                        .addBudget(id: nil, categoryID: nil, date: session.filter.startDate),
                        in: section)
                }
                .tint(Color.primary)
                .disabled(finance.categories.isEmpty || finance.isLoading)
            }
        }
        .deletionDialog(goals)
        .errorAlert($goals.error)
        .refreshable { await finance.load() }
        .navigationTitle("Budgets")
    }
}

struct BudgetsSummarySection: View {
    @Environment(GoalsModel.self) private var goals

    var body: some View {
        let overview = goals.overview
        Section {
            BudgetsOverviewCard(overview: overview)
            if let daily = overview.dailyAllowance, let days = overview.daysLeft {
                SummaryRow(
                    symbol: "calendar", color: .positive, title: "You can spend",
                    detail: "over the next \(days) days",
                    value: "\(daily.formatted(.appCurrency)) per day",
                    valueColor: .positive)
            }
            if overview.unbudgeted > 0 {
                SummaryRow(
                    symbol: "questionmark.folder", color: .secondary, title: "Outside budgets",
                    detail: "spent in categories without a budget",
                    value: "\(overview.unbudgeted.formatted(.appCurrency))", valueColor: .primary)
            }
        } header: {
            BudgetsOverviewHeader(title: "Month Summary", overview: overview)
        }
    }
}

private struct SummaryRow: View {
    let symbol: String
    let color: Color
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let value: LocalizedStringKey
    let valueColor: Color

    var body: some View {
        HStack(spacing: .spaceM) {
            SymbolBadge(symbol, color: color, size: .badgeM)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                HStack(alignment: .firstTextBaseline, spacing: .spaceS) {
                    Text(title).font(.rowTitle).frame(maxWidth: .infinity, alignment: .leading)
                    Text(value)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(valueColor)
                        .amountLine()
                }
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct UnbudgetedSection: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        let categories = finance.categoriesWithoutBudgets
        if !categories.isEmpty, session.filter.isFilteringByDate {
            Section {
                FlowLayout(spacing: .spaceS) {
                    ForEach(categories) { category in
                        let color = Color(hex: category.color)
                        Button {
                            open(
                                .addBudget(
                                    id: nil, categoryID: category.id,
                                    date: session.filter.startDate),
                                in: section)
                        } label: {
                            HStack(spacing: .spaceXS) {
                                Image(systemName: "plus")
                                Text(category.name)
                            }
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .fixedSize()
                            .foregroundStyle(color)
                            .padding(.horizontal, .spaceM)
                            .padding(.vertical, .spaceS)
                            .background(color.opacity(.opacityFill), in: .capsule)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Create a \(category.name) budget")
                    }
                }
                .padding(.vertical, .space2XS)
            } header: {
                Text("No Budget").sectionTitle()
            } footer: {
                Text("Tap a category to set how much you want to spend on it this month.")
            }
        }
    }
}
