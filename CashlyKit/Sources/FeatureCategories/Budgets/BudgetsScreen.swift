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
                Button("Novo orçamento", systemImage: "plus") {
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
        .navigationTitle("Orçamentos")
    }
}

struct BudgetsSummarySection: View {
    @Environment(GoalsModel.self) private var goals

    var body: some View {
        let overview = goals.overview
        Section {
            BudgetsOverviewCard(overview: overview)
            if let daily = overview.dailyAllowance, let days = overview.daysLeft {
                LabeledContent {
                    Text("\(daily.formatted(.appCurrency)) por dia")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.positive)
                } label: {
                    Text("Dá para gastar")
                    Text("nos próximos \(days) dias")
                }
            }
            if overview.unbudgeted > 0 {
                LabeledContent {
                    Text(overview.unbudgeted.formatted(.appCurrency)).fontWeight(.semibold)
                } label: {
                    Text("Fora dos orçamentos")
                    Text("gasto em categorias sem orçamento")
                }
            }
        } header: {
            Text("Resumo do mês").sectionTitle()
        }
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
                FlowLayout(spacing: 8) {
                    ForEach(categories) { category in
                        let color = Color(hex: category.color)
                        Button {
                            open(
                                .addBudget(
                                    id: nil, categoryID: category.id,
                                    date: session.filter.startDate),
                                in: section)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                Text(category.name)
                            }
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .fixedSize()
                            .foregroundStyle(color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(color.opacity(0.15), in: .capsule)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Criar orçamento de \(category.name)")
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Sem orçamento").sectionTitle()
            } footer: {
                Text("Toque numa categoria para definir quanto quer gastar nela neste mês.")
            }
        }
    }
}
