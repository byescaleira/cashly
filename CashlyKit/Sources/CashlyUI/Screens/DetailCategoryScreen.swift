import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import CashlyResource
import Foundation
import SwiftUI

public struct DetailCategoryScreen: View {

    @Environment(MainViewModel.self) var state
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    private let categoryID: String
    private var category: CashlyDomain.Category {
        state.allCategories.first { $0.id == categoryID }
            ?? CashlyDomain.Category(
                id: categoryID, user: .empty, name: "Categoria indisponível", color: "808080",
                icon: "questionmark")
    }

    public init(categoryID: String) {
        self.categoryID = categoryID
    }

    public var body: some View {
        List {
            headerSection
            descriptionSection
            budgetsSection
        }
        .navigationTitle(category.name.capitalized)
        .environment(\.isLoading, state.isLoading)
        .refreshable { await state.load() }
    }

    var headerSection: some View {
        Section {
            CashlyText(state.budget(for: category)?.summary)
                .frame(maxWidth: .infinity)
                .cashly(alignment: .center)
                .cashlyPadding()
        } header: {
            CashlyVStack(spacing: .medium) {
                iconView
                amountView
                CategoryVariationView(category: category)
                    .scaleEffect(1.2)
            }
            .cashly(alignment: .center)
            .frame(maxWidth: .infinity)
            .cashlyPadding(.vertical, .medium)
        }
    }

    var descriptionSection: some View {
        Section {

        }
    }

    var iconView: some View {
        CashlySymbol(category.icon)
            .cashly(font: .system(size: 30))
            .cashly(color: .hex(category.color))
            .frame(width: 70, height: 70)
            .cashly(background: .color((Color(hex: category.color)).opacity(0.2)))
            .cashly(clip: .circle)
            .overlay {
                Circle()
                    .stroke(Color(hex: category.color), lineWidth: 5)
                    .frame(width: 80, height: 80)
            }
            .cashly(symbol: .bounce.byLayer, options: .repeat(.continuous).speed(0.1))
    }

    var amountView: some View {
        CashlyVStack(spacing: .zero) {
            CashlyText(state.budgetsAmount(for: category).currency())
                .cashly(font: .largeTitle, weight: .black)
                .cashly(color: .text)

            CashlyText(state.expensesAmount(for: category).currency())
                .cashly(font: .title2, weight: .bold)
                .cashly(color: .textSecondary)
        }
    }

    @ViewBuilder
    var budgetsSection: some View {
        let budgets = state.budgets(for: category)
        if !budgets.isEmpty {
            Section {
                ForEach(budgets) { budget in
                    Button {
                        open(.addBudget(id: budget.id, categoryID: nil, date: nil), in: section)
                    } label: {
                        budgetItemView(budget: budget)
                    }
                    .cashly(color: .text)
                }
            } header: {
                CashlyText("Budgets")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
        }
    }

    func budgetItemView(budget: Budget) -> some View {
        CashlyHStack(spacing: .medium) {
            let transactionAmount = state.expensesAmount(for: budget)
            let budgetAmount = budget.amount
            let variation = transactionAmount / (budgetAmount.isZero ? 1 : budgetAmount)
            CashlyVStack(alignment: .leading, spacing: .extraSmall) {
                CashlyText(
                    budget.date.string.date(with: .cashly(.yearMonth))?.string(
                        with: .cashly(.status))
                )
                .cashly(font: .callout, weight: .semibold)
                CashlyText(variation.percentage)
            }

            Spacer()

            CashlyVStack(alignment: .trailing, spacing: .extraSmall) {
                CashlyText(budgetAmount.currency())
                    .cashly(font: .callout, weight: .semibold)
                CashlyText(transactionAmount.currency())
            }

            CashlySymbol("chevron.forward")
                .cashly(color: .disabled)
        }
        .cashly(font: .callout)
    }

}
