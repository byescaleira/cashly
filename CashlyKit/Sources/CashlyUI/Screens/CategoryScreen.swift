import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import CashlyResource
import Foundation
import SwiftUI

public struct CategoryScreen: View {

    @Environment(MainViewModel.self) var state
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    public init() {}

    public var body: some View {
        List {
            CategoryBalanceView()
            EmptyCategoryView()
            EmptyBudgetView(budgets: state.budgets)
            EmptyUserView()
            DataStatusView()
            categoriesWithoutBudgetsSection
            categoriesSection
        }
        .lineLimit(2)
        .cashly(font: .callout)
        .toolbar {
            ToolbarItem(placement: .navigation) { UserItemView() }
            ToolbarItem { FilterItemView() }
            CashlyToolbarSpacer()
            ToolbarItem { addButton }
        }
        .environment(\.isLoading, state.isLoading)
        .refreshable { await state.load() }
        .navigationTitle("Categories")
    }

    @ViewBuilder
    var categoriesSection: some View {
        let categories = state.categoriesWithBudgets
        if !categories.isEmpty {
            Section {
                ForEach(categories, id: \.id) { category in
                    Button {
                        open(.detailCategory(id: category.id), in: section)
                    } label: {
                        categoryItemView(category: category)
                    }
                    .cashly(tint: .text)
                    .cashlyEdit { open(.addCategory(id: category.id), in: section) }
                }
            } header: {
                CashlyText("Budgets")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
        }
    }

    @ViewBuilder
    var categoriesWithoutBudgetsSection: some View {
        let categories = state.categoriesWithoutBudgets
        if !categories.isEmpty, state.filter.isFilteringByDate {
            Section {
                CashlyVStack(alignment: .leading) {
                    CashlyText(
                        "This category doesn’t have a budget yet. Add one below to help track your spending."
                    )
                    categoriesWithoutBudgetsView(categories: categories)
                }
                .frame(maxWidth: .infinity)
            } header: {
                CashlyText("Want more control?")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
        }
    }

    func categoriesWithoutBudgetsView(categories: [CashlyDomain.Category]) -> some View {
        CashlyHorizontalList { _ in
            CashlyHStack(alignment: .center) {
                ForEach(categories) { category in
                    Button {
                        open(
                            .addBudget(
                                id: nil, categoryID: category.id, date: state.filter.startDate),
                            in: section
                        )
                    } label: {
                        categoryIcon(category: category, isAnimated: true)
                    }
                    .cashlyPadding()
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
    }

    func categoryItemView(category: CashlyDomain.Category) -> some View {
        CashlyHStack(spacing: .medium) {
            categoryIcon(category: category)

            CashlyVStack(alignment: .leading, spacing: .extraSmall) {
                CashlyHStack {
                    CashlyText(category.name)
                    Spacer()
                }
                .cashly(font: .callout, weight: .semibold)

                CashlyText(state.budget(for: category)?.summary)
                    .cashly(color: .textSecondary)
            }

            Spacer()

            CashlyVStack(alignment: .trailing, spacing: .extraSmall) {
                let budgetAmount = state.budgetsAmount(for: category)
                let expensesAmount = state.expensesAmount(for: category)

                CategoryVariationView(category: category)
                    .scaleEffect(0.7)
                    .padding(.trailing, -6)

                if budgetAmount > .zero {
                    CashlyText(budgetAmount.currency())
                        .cashly(font: .callout, weight: .semibold)
                }

                if expensesAmount > .zero {
                    CashlyText(expensesAmount.currency())
                        .cashly(font: .callout, weight: .semibold)
                        .cashly(color: .textSecondary)
                }
            }
            .cashly(alignment: .trailing)

            CashlySymbol("chevron.forward")
                .cashly(color: .disabled)
        }
        .cashlyEdit { open(.addCategory(id: category.id), in: section) }
    }

    func categoryIcon(category: CashlyDomain.Category, isAnimated: Bool = false) -> some View {
        CashlySymbol(category.icon)
            .cashly(font: .system(size: 18))
            .cashly(color: .hex(category.color))
            .frame(width: 40, height: 40)
            .cashly(background: .color((Color(hex: category.color)).opacity(0.2)))
            .cashly(clip: .circle)
            .overlay {
                if isAnimated {
                    Circle()
                        .stroke(Color(hex: category.color), lineWidth: 2)
                        .frame(width: 45, height: 45)
                }
            }
            .cashly(if: isAnimated) {
                $0.cashly(symbol: .bounce.byLayer, options: .repeat(.continuous).speed(0.1))
            }
    }

    @ViewBuilder
    var addButton: some View {
        if !state.users.isEmpty {
            Button {
                open(.addCategory(id: nil), in: section)
            } label: {
                CashlySymbol("plus")
                    .cashly(color: .text)
            }
            .disabled(state.isLoading)
        }
    }

}
