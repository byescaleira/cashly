//
//  InsightsScreen.swift
//  CashlyKit
//
//  Spending breakdown using Swift Charts. Reads pre-computed
//  `transactionsAmountByCategory` + `biggestTagsCache` from MainState
//  so the chart body never iterates the raw transaction list.
//

import SwiftUI
import Charts
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct InsightsScreen: CashlyView {
    @Environment(\.mainState) var state
    @Environment(\.router) var router

    public init() {}

    @Environment(\.action) var action

    public var body: some View {
        CashlyList {
            summarySection
            categoriesSection
            tagsSection
        }
        .toolbar {
            ToolbarItem(placement: .navigation) { UserItemView() }
        }
        .refreshable {
            action(.main(.fetch))
            try? await Task.sleep(nanoseconds: 400_000_000)
        }
        .onAppear { action(.main(.fetch)) }
        .navigationTitle(CashlyL10n.string("Insights"))
    }

    var summarySection: some View {
        Section {
            CashlyHStack {
                summaryTile(
                    title: CashlyL10n.string("Income"),
                    value: state.incomeAmount,
                    color: .green,
                    icon: "arrow.down.left"
                )
                summaryTile(
                    title: CashlyL10n.string("Expenses"),
                    value: state.transactionsAmount,
                    color: .red,
                    icon: "arrow.up.right"
                )
            }
            CashlyHStack {
                summaryTile(
                    title: CashlyL10n.string("Net"),
                    value: state.netAmount,
                    color: state.netAmount >= 0 ? .green : .red,
                    icon: "equal"
                )
                summaryTile(
                    title: CashlyL10n.string("Pending loans"),
                    value: state.pendingLoansAmount,
                    color: .orange,
                    icon: "arrow.left.arrow.right"
                )
            }
        } header: {
            CashlyText(CashlyL10n.string("Summary"))
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }

    @ViewBuilder
    private func summaryTile(
        title: String,
        value: Double,
        color: Color,
        icon: String
    ) -> some View {
        CashlyVStack(alignment: .leading, spacing: .extraSmall) {
            CashlyHStack(spacing: .extraSmall) {
                CashlySymbol(icon)
                    .cashly(color: .color(color))
                    .cashly(font: .caption, weight: .bold)
                CashlyText(title)
                    .cashly(color: .textSecondary)
                    .cashly(font: .caption)
            }
            CashlyText(CashlyCurrency.format(value))
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .color(color))
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cashlyPadding(.all, .small)
        .background(color.opacity(0.1), in: CashlyShape.rounded(radius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(CashlyCurrency.format(value))")
    }

    var categoriesSection: some View {
        Section {
            if categoryData.isEmpty {
                CashlyText(CashlyL10n.string("No data yet."))
                    .cashly(color: .textSecondary)
            } else {
                Chart(categoryData, id: \.id) { entry in
                    BarMark(
                        x: .value("Amount", entry.amount),
                        y: .value("Category", entry.name)
                    )
                    .foregroundStyle(Color(hex: entry.color))
                }
                .frame(minHeight: 240)
                // Spelled-out summary for VoiceOver — Chart's full
                // descriptor APIs require non-trivial conformances;
                // a label covers the bar-chart case well enough.
                .accessibilityLabel(categoryAccessibilityLabel)
                .cashlyProGate(isPro: state.isPro, trigger: .insightsTab)
            }
        } header: {
            CashlyText(CashlyL10n.string("Spending by category"))
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }

    var tagsSection: some View {
        Section {
            if state.biggestTags.isEmpty {
                CashlyText(CashlyL10n.string("No tag activity yet."))
                    .cashly(color: .textSecondary)
            } else {
                ForEach(state.biggestTags, id: \.id) { tag in
                    CashlyHStack {
                        CashlySymbol(tag.icon)
                            .cashly(color: .hex(tag.color))
                            .accessibilityHidden(true)
                        CashlyText(tag.name)
                        CashlySpacer()
                        CashlyText(CashlyCurrency.format(state.transactionsAmount(for: tag)))
                            .cashly(font: .caption, weight: .semibold)
                            .cashly(color: .textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        } header: {
            CashlyText(CashlyL10n.string("Top tags"))
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }

    // MARK: - Derived chart data

    private struct CategoryEntry: Identifiable, Equatable {
        let id: String
        let name: String
        let amount: Double
        let color: String
    }

    private var categoryData: [CategoryEntry] {
        state.categories
            .map { category in
                CategoryEntry(
                    id: category.id,
                    name: category.name,
                    amount: state.transactionsAmount(for: category),
                    color: category.color
                )
            }
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
    }

    private var categoryAccessibilityLabel: String {
        let parts = categoryData.map { "\($0.name) \(CashlyCurrency.format($0.amount))" }
        return CashlyL10n.string("Spending by category") + ": " + parts.joined(separator: ", ")
    }

    public static var mock: some View {
        InsightsScreen()
    }
}

#if DEBUG
#Preview {
    NavigationView {
        InsightsScreen
            .cashlyPreview()
    }
}
#endif
