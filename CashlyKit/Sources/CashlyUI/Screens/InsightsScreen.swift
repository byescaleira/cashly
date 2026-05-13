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

    public var body: some View {
        Form {
            categoriesSection
            tagsSection
        }
        .navigationTitle(CashlyL10n.string("Insights"))
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
            }
        } header: {
            CashlyText(CashlyL10n.string("Spending by category"))
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
