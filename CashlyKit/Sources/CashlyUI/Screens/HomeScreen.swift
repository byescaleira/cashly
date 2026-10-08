import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import CashlyResource
import Foundation
import SwiftUI

public struct HomeScreen: View {

    @Environment(IntelligenceViewModel.self) var intelligence
    @Environment(MainViewModel.self) var state
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    public init() {}

    public var body: some View {
        List {
            EmptyUserView()
            DataStatusView()
            EmptyCategoryView()
            EmptyBudgetView(budgets: state.budgets)
            BalanceView()
            availableSection
            varianceSection
            biggestTransactionSection
            tagsSection
            SpendingForecastSection()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) { UserItemView() }
            ToolbarItem { FilterItemView() }
        }
        .refreshable { await state.load() }
        .navigationTitle((state.user?.selfFirstName ?? "") + "Home")
        .onChange(of: state.categories, initial: true) {
            selectedCompareCategory =
                state.categories.first { $0.id == selectedCompareCategory?.id }
                ?? state.categories.first
            selectedAvailableCategory =
                state.categories.first { $0.id == selectedAvailableCategory?.id }
                ?? state.categories.first
        }
        .onChange(of: state.tags, initial: true) {
            selectedTag = state.tags.first { $0.id == selectedTag?.id } ?? state.tags.first
        }
        .onChange(of: state.biggestTransactions) { selectedBiggestTransactionIndex = 0 }

    }

    @State var selectedTag: Tag?

    @ViewBuilder
    var tagsSection: some View {
        EmptyTagView()

        if !state.tags.isEmpty {
            Section {
                let data: [CashlyChartPoint] = state.tags.map {
                    let amount = state.expensesAmount(for: $0)
                    return CashlyChartPoint(id: $0.id, label: $0.name.capitalized, amount: amount)
                }

                if let selectedTag {
                    let amount = state.expensesAmount(for: selectedTag)

                    Button {
                        open(.addTag(id: selectedTag.id), in: section)
                    } label: {
                        CashlyHStack {
                            CashlyText(selectedTag.name.uppercased())
                                .cashly(font: .caption2, weight: .bold)
                                .cashly(color: .hex(selectedTag.color))
                                .cashlyPadding()
                                .cashlyPadding(.horizontal, .extraSmall)
                                .cashlyContentSurface(
                                    tint: .init(hex: selectedTag.color).opacity(0.2), in: .capsule)

                            Spacer()

                            CashlyText(amount.currency())
                                .cashly(font: .title3, weight: .bold)
                                .cashly(color: .text)
                                .contentTransition(.numericText())

                            CashlySymbol("chevron.forward")
                                .cashly(color: .disabled)
                        }
                        .animation(.bouncy, value: amount)
                    }
                    .cashly(tint: .text)
                }

                CashlyChart(
                    type: .line,
                    startItemsAmount: 4.5,
                    data: data
                )

                Button {
                    open(.addTag(id: nil), in: section)
                } label: {
                    CashlyHStack {
                        CashlyText("Add new tag")
                        Spacer()
                        CashlySymbol("chevron.forward")
                            .cashly(color: .disabled)
                    }
                }
                .cashly(tint: .text)
            } header: {
                CashlyVStack(alignment: .leading, spacing: .small) {
                    CashlyText("Tags")
                        .cashly(font: .title3, weight: .semibold)
                        .cashly(color: .text)

                    tagsView
                }
                .frame(maxWidth: .infinity)
                .cashly(alignment: .leading)
            }
        }
    }

    var tagsView: some View {
        CashlyVStack(alignment: .leading, spacing: .small) {
            CashlyHorizontalList { proxy in
                CashlyHStack {
                    ForEach(state.tags) { tag in
                        Button {
                            selectedTag = tag
                        } label: {
                            CashlySymbol(tag.icon)
                                .cashly(font: .system(size: 20))
                                .cashly(
                                    color: selectedTag == tag ? .hex(tag.color) : .color(.secondary)
                                )
                                .frame(width: 45, height: 45)
                                .cashly(
                                    background: .color(
                                        (selectedTag == tag ? Color(hex: tag.color) : .secondary)
                                            .opacity(0.2))
                                )
                                .cashly(clip: .circle)
                                .overlay {
                                    Circle()
                                        .stroke(
                                            selectedTag == tag ? Color(hex: tag.color) : .secondary,
                                            lineWidth: 3
                                        )
                                        .frame(width: 50, height: 50)
                                }
                                .opacity(selectedTag == tag ? 1 : 0.3)
                                .cashly(if: tag == selectedTag) {
                                    $0.cashly(
                                        symbol: .bounce.byLayer,
                                        options: .repeat(.continuous).speed(0.1))
                                }
                        }
                        .id(tag)
                        .cashlyPadding()
                    }
                }
                .task(id: selectedTag) {
                    do {
                        try await Task.sleep(for: .milliseconds(200))
                        try Task.checkCancellation()
                        withAnimation(.bouncy.speed(0.5)) {
                            proxy.scrollTo(selectedTag, anchor: .center)
                        }
                    } catch {}
                }
                .animation(.bouncy, value: selectedTag)
                .padding(.horizontal, 40)
            }
            .onAppear { selectedTag = selectedTag == nil ? state.tags.first : selectedTag }
            .padding(.horizontal, -40)
        }
    }

    @State var selectedCompareCategory: CashlyDomain.Category?

    @ViewBuilder
    var varianceSection: some View {
        if !state.categories.isEmpty,
            !state.budgets.isEmpty
        {
            Section {
                let data = state.categories.map { category in
                    let budgetAmount = state.budgetsAmount(for: category)
                    let expensesAmount = state.expensesAmount(for: category)
                    return CashlyComparisonPoint(
                        id: category.id, label: category.name.capitalized, planned: budgetAmount,
                        spent: expensesAmount)
                }

                let selectedData = data.first(where: {
                    $0.id == selectedCompareCategory?.id
                })
                let budgetAmount = selectedData?.planned ?? .zero
                let expensesAmount = selectedData?.spent ?? .zero
                let variation = expensesAmount / (budgetAmount == .zero ? 1 : budgetAmount)
                let percentage = variation > 1 ? 1 - variation : variation

                CashlyHStack(spacing: .extraSmall) {
                    CashlyVStack(alignment: .leading, spacing: .extraSmall) {
                        CashlyText(budgetAmount.currency())
                            .cashly(font: .title3, weight: .bold)
                            .cashly(color: .text)
                            .contentTransition(.numericText())
                            .animation(.bouncy, value: budgetAmount)

                        CashlyText("Budget")
                            .cashly(font: .callout, weight: .semibold)
                            .cashly(color: .info)
                    }
                    .cashly(alignment: .leading)

                    Spacer()

                    CashlyVStack(alignment: .trailing, spacing: .extraSmall) {
                        CashlyText(expensesAmount.currency())
                            .cashly(font: .title3, weight: .bold)
                            .cashly(color: .text)
                            .contentTransition(.numericText())
                            .animation(.bouncy, value: expensesAmount)

                        CashlyHStack(spacing: .small) {
                            CashlyText(percentage.percentage)
                                .cashly(font: .footnote, weight: .bold)
                                .cashly(color: .textSecondary)
                                .contentTransition(.numericText())
                                .animation(.bouncy, value: percentage)

                            CashlyText("Expense")
                                .cashly(font: .callout, weight: .semibold)
                                .cashly(color: .primary)
                        }
                    }
                    .cashly(alignment: .trailing)
                }

                CashlyCompareChart(type: .bar, data: data)
            } header: {
                CashlyVStack(alignment: .leading, spacing: .small) {
                    CashlyText("Variance")
                        .cashly(font: .title3, weight: .semibold)
                        .cashly(color: .text)

                    categoriesView(selected: $selectedCompareCategory)
                }
                .frame(maxWidth: .infinity)
                .cashly(alignment: .leading)
            }
        }
    }

    func categoriesView(selected: Binding<CashlyDomain.Category?>) -> some View {
        CashlyVStack(alignment: .leading, spacing: .small) {
            CashlyHorizontalList { proxy in
                CashlyHStack {
                    ForEach(state.categories) { category in
                        Button {
                            selected.wrappedValue = category
                        } label: {
                            CashlySymbol(category.icon)
                                .cashly(font: .system(size: 20))
                                .cashly(
                                    color: selected.wrappedValue == category
                                        ? .hex(category.color) : .color(.secondary)
                                )
                                .frame(width: 45, height: 45)
                                .cashly(
                                    background: .color(
                                        (selected.wrappedValue == category
                                            ? Color(hex: category.color) : .secondary)
                                            .opacity(0.2))
                                )
                                .cashly(clip: .circle)
                                .overlay {
                                    Circle()
                                        .stroke(
                                            selected.wrappedValue == category
                                                ? Color(hex: category.color) : .secondary,
                                            lineWidth: 3
                                        )
                                        .frame(width: 50, height: 50)
                                }
                                .opacity(selected.wrappedValue == category ? 1 : 0.3)
                                .cashly(if: category == selected.wrappedValue) {
                                    $0.cashly(
                                        symbol: .bounce.byLayer,
                                        options: .repeat(.continuous).speed(0.1))
                                }
                        }
                        .id(category)
                        .cashlyPadding()
                    }
                }
                .task(id: selected.wrappedValue) {
                    do {
                        try await Task.sleep(for: .milliseconds(200))
                        try Task.checkCancellation()
                        withAnimation(.bouncy.speed(0.5)) {
                            proxy.scrollTo(selected.wrappedValue, anchor: .center)
                        }
                    } catch {}
                }
                .animation(.bouncy, value: selected.wrappedValue)
                .padding(.horizontal, 40)
            }
            .onAppear {
                selected.wrappedValue =
                    selected.wrappedValue == nil ? state.categories.first : selected.wrappedValue
            }
            .padding(.horizontal, -40)
        }
    }

    @State var selectedAvailableCategory: CashlyDomain.Category?

    @ViewBuilder
    var availableSection: some View {
        if !state.budgets.isEmpty {
            Section {
                if let selectedAvailableCategory {
                    let budgetsAmount = state.budgetsAmount(for: selectedAvailableCategory)
                    let expensesAmount = state.expensesAmount(for: selectedAvailableCategory)
                    let availableCategory = budgetsAmount - expensesAmount
                    let conventionalVariation =
                        expensesAmount / (budgetsAmount.isZero ? 1 : budgetsAmount)
                    let variation = 1 - conventionalVariation
                    Menu {
                        Picker(selection: $selectedAvailableCategory) {
                            ForEach(state.categories) {
                                CashlyText($0.name)
                                    .tag($0)
                            }
                        } label: {
                            EmptyView()
                        }
                    } label: {
                        CashlyHStack(spacing: .medium) {
                            CashlyText("Selected category")
                                .cashly(font: .body)
                                .cashly(color: .text)

                            Spacer()

                            CashlyHStack {
                                CashlyText(selectedAvailableCategory.name.capitalized)
                                    .cashly(font: .body, weight: .semibold)

                                CashlySymbol("chevron.up.chevron.down")
                                    .cashly(font: .footnote, weight: .semibold)
                            }
                            .cashly(color: .primary)
                        }
                    }

                    CashlyHStack(spacing: .small) {
                        CashlyText(availableCategory.currency())
                            .cashly(font: .title3, weight: .bold)
                        CashlyText("/  \(budgetsAmount.currency() ?? "")")
                            .cashly(font: .footnote)
                            .cashly(color: .textSecondary)
                            .cashlyPadding(.bottom, .negative(.extraSmall))

                        Spacer()

                        CashlyText(variation.percentage)
                            .cashly(font: .caption2, weight: .bold)
                            .cashly(color: .color(conventionalVariation.variationColor))
                            .cashlyPadding()
                            .cashlyPadding(.horizontal, .extraSmall)
                            .cashlyContentSurface(
                                tint: conventionalVariation.variationColor.opacity(0.2),
                                in: .capsule)
                    }
                }
            } header: {
                CashlyVStack(alignment: .leading, spacing: .small) {
                    let budgetsAmount = state.budgetsAmount
                    let expensesAmount = state.expensesAmount
                    let available = budgetsAmount - expensesAmount

                    CashlyText("Available")
                        .cashly(font: .title3, weight: .semibold)
                        .cashly(color: .text)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    CashlyVStack(spacing: .extraSmall) {
                        CashlyText(available.currency())
                            .cashly(font: .largeTitle, weight: .black)
                            .cashly(color: .text)
                            .cashly(alignment: .center)

                        CashlyText(budgetsAmount.currency())
                            .cashly(font: .title3, weight: .semibold)
                            .cashly(color: .textSecondary)
                            .cashly(alignment: .center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .cashlyPadding(.vertical, .large)
                }
                .onAppear {
                    selectedAvailableCategory =
                        selectedAvailableCategory == nil
                        ? state.categories.first : selectedAvailableCategory
                }
            }
        }
    }

    @State var selectedBiggestTransactionIndex: Int = .zero

    @ViewBuilder
    var biggestTransactionSection: some View {
        let transactions = state.biggestTransactions
        if !transactions.isEmpty {
            Section {
                TabView(selection: $selectedBiggestTransactionIndex) {
                    ForEach(transactions.enumerated(), id: \.offset) { index, transaction in
                        CashlyVStack(spacing: .small) {
                            let category = transaction.category
                            Spacer()
                            CashlyText(category.name.uppercased())
                                .cashly(font: .caption2, weight: .bold)
                                .cashly(color: .hex(category.color))
                                .cashlyPadding()
                                .cashlyPadding(.horizontal, .extraSmall)
                                .cashlyContentSurface(
                                    tint: .init(hex: category.color).opacity(0.2), in: .capsule)

                            CashlyText(
                                transaction.billingMoney(
                                    in: state.filter.isFilteringByDate
                                        ? state.filter.startDate.timeIntervalSince1970.yearMonth
                                        : nil
                                ).formatted
                            )
                            .cashly(font: .title, weight: .bold)
                            .cashly(color: .text)

                            CashlyText(transaction.summary)
                                .cashly(color: .textSecondary)
                            Spacer()
                        }
                        .cashly(alignment: .center)
                        .padding(.horizontal, 50)
                        .tag(index)
                    }
                }
                .frame(height: 170)
                .padding(.horizontal, -20)
                .animation(.bouncy, value: selectedBiggestTransactionIndex)
                #if os(iOS)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
            } header: {
                CashlyHStack {
                    CashlyText("Top Spending")
                        .cashly(font: .title3, weight: .semibold)
                        .cashly(color: .text)

                    Spacer()

                    CashlyHStack(spacing: .extraSmall) {
                        ForEach(transactions.enumerated(), id: \.offset) { index, _ in
                            Circle()
                                .frame(width: 8, height: 8)
                                .foregroundStyle(
                                    index == selectedBiggestTransactionIndex
                                        ? Color.accentColor : .primary.opacity(0.1)
                                )
                        }
                    }
                    .cashlyPadding()
                    .cashlyPadding(.horizontal, .extraSmall)
                    .cashlyContentSurface(tint: .secondary.opacity(0.2), in: .capsule)
                }
            } footer: {

            }
        }
    }

}
