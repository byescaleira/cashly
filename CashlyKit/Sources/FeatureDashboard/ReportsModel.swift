import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class ReportsModel {
    public struct Comparison: Equatable {
        public let planned: Double
        public let spent: Double
        public let ratio: Double
    }

    public struct SyncKey: Hashable {
        let categories: [String]
        let tags: [String]
    }

    public var selectedTag: Tag?
    public var comparedCategory: CashlyDomain.Category?
    @ObservationIgnored private let finance: FinanceModel

    public init(finance: FinanceModel) {
        self.finance = finance
    }

    public var syncKey: SyncKey {
        SyncKey(categories: finance.categories.map(\.id), tags: finance.tags.map(\.id))
    }

    public func sync() {
        comparedCategory =
            finance.categories.first { $0.id == comparedCategory?.id } ?? finance.categories.first
        selectedTag = finance.tags.first { $0.id == selectedTag?.id } ?? finance.tags.first
    }

    public var comparisonPoints: [ComparisonPoint] {
        finance.categories.map {
            ComparisonPoint(
                id: $0.id, label: $0.name.capitalized, planned: finance.budgetsAmount(for: $0),
                spent: finance.expensesAmount(for: $0))
        }
    }

    public var comparison: Comparison {
        let point = comparisonPoints.first { $0.id == comparedCategory?.id }
        let planned = point?.planned ?? .zero
        let spent = point?.spent ?? .zero
        let ratio = BudgetUsage(spent: spent, budgeted: planned).ratio
        return Comparison(planned: planned, spent: spent, ratio: ratio > 1 ? 1 - ratio : ratio)
    }

    public var tagPoints: [ChartPoint] {
        finance.tags.map {
            ChartPoint(
                id: $0.id, label: $0.name.capitalized, amount: finance.expensesAmount(for: $0))
        }
    }

    public var selectedTagAmount: Double {
        selectedTag.map { finance.expensesAmount(for: $0) } ?? .zero
    }
}
