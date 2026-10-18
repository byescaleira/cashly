import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

public struct BudgetConflictScreen: View {
    @Environment(BudgetConflictModel.self) private var model
    @Environment(FinanceModel.self) private var finance
    @Environment(\.close) private var close

    public init() {}

    public var body: some View {
        @Bindable var model = model
        AdaptiveList {
            if let conflict = model.conflict, let first = conflict.budgets.first {
                Section {
                    HStack(spacing: .spaceM) {
                        SymbolBadge(first.category.icon, color: Color(hex: first.category.color))
                        VStack(alignment: .leading, spacing: .spaceHairline) {
                            Text(first.category.name).font(.rowTitle)
                            Text(
                                first.month.startDate.formatted(
                                    .dateTime.month(.wide).year().locale(.app))
                            )
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                } header: {
                    Text("Resolve Budget").sectionTitle()
                } footer: {
                    Text(
                        "Choose the planned amount to keep. Transactions will be grouped under that budget; the other records are kept as the conflict's history."
                    )
                }
                ForEach(Array(conflict.budgets.enumerated()), id: \.element.id) { index, budget in
                    ConflictOptionSection(budget: budget, number: index + 1)
                }
            } else if model.isLoading {
                Section { ProgressView().frame(maxWidth: .infinity) }
            } else {
                Section {
                    Text("This conflict was already resolved. Refresh the data to continue.")
                }
            }
        }
        .fontDesign(.rounded)
        .navigationTitle("Resolve Budget")
        .task(id: finance.contentGeneration) { await model.load() }
        .disabled(model.isLocked)
        .interactiveDismissDisabled(model.isSaving)
        .errorAlert($model.error)
    }
}

private struct ConflictOptionSection: View {
    @Environment(BudgetConflictModel.self) private var model
    @Environment(\.close) private var close
    let budget: Budget
    let number: Int

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(budget.money.doubleValue.formatted(.appCurrency))
                    .font(.amountRow)
                    .amountLine()
                if !budget.summary.isEmpty {
                    Text(budget.summary).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, .space2XS)
            .accessibilityElement(children: .combine)
            Button("Keep This Budget", systemImage: "checkmark.circle") {
                Task { if await model.keep(budget) { close() } }
            }
            .font(.buttonLabel)
        } header: {
            Text("Option \(number)").sectionTitle()
        }
    }
}
