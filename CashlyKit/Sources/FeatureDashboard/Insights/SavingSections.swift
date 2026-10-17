import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct RecurringSection: View {
    @Environment(InsightsModel.self) private var insights
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let recurrences = insights.recurrences {
            ProOnly {
                Section {
                    ForEach(recurrences.items) { item in
                        RecurringRow(item: item)
                            .swipeActions {
                                Button("Keep", systemImage: "checkmark") { keep(item) }
                                    .tint(.info)
                            }
                            .contextMenu {
                                Button("Keep", systemImage: "checkmark") { keep(item) }
                            }
                    }
                } header: {
                    FigureHeader(title: "Recurring Charges", amount: recurrences.yearly) {
                        Text(recurrences.caption)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text(
                        "Same description and a similar amount every month. Review what you no longer use, and swipe the charges you keep to hide them."
                    )
                }
            }
        }
    }

    private func keep(_ item: InsightsModel.Recurring) {
        withAnimation(reduceMotion ? nil : .smooth) { insights.keep(item) }
    }
}

private struct RecurringRow: View {
    let item: InsightsModel.Recurring

    var body: some View {
        AdaptiveRow(spacing: .spaceM) {
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(item.name).font(.rowTitle)
                Text(item.detail).font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(item.amount)
                .font(.callout.weight(.semibold))
                .contentTransition(.numericText(value: item.monthly))
                .amountLine()
        }
        .accessibilityElement(children: .combine)
    }
}

struct BudgetIdeasSection: View {
    @Environment(InsightsModel.self) private var insights
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let ideas = insights.budgetIdeas
        if !ideas.isEmpty {
            ProOnly {
                Section {
                    ForEach(ideas) { item in
                        Button {
                            open(item.route, in: section)
                        } label: {
                            BudgetIdeaRow(item: item)
                        }
                        .tint(Color.primary)
                        .swipeActions {
                            Button("Don't Suggest", systemImage: "eye.slash") { hide(item) }
                        }
                        .contextMenu {
                            Button("Don't Suggest", systemImage: "eye.slash") { hide(item) }
                        }
                    }
                } header: {
                    Text("Budgets to Create").sectionTitle()
                } footer: {
                    Text(
                        "Categories with spending in most months and no budget this month. Tap one to create its budget, or swipe it to stop the suggestion."
                    )
                }
            }
        }
    }

    private func hide(_ item: InsightsModel.BudgetIdea) {
        withAnimation(reduceMotion ? nil : .smooth) { insights.hide(item) }
    }
}

private struct BudgetIdeaRow: View {
    @Environment(\.appTint) private var appTint
    let item: InsightsModel.BudgetIdea

    var body: some View {
        HStack(spacing: .spaceM) {
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(item.name).font(.rowTitle)
                Text(item.detail).font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "plus")
                .font(.callout.weight(.semibold))
                .foregroundStyle(appTint)
                .accessibilityHidden(true)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens a new budget for this category")
    }
}
