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

    public struct ForecastKey: Hashable {
        let userID: String?
        let month: YearMonth?
        let categoryIDs: [String]
        let revision: String
        let modelDates: [Date]
    }

    public var selectedTag: Tag?
    public var comparedCategory: CashlyDomain.Category?
    public private(set) var forecast = 0.0
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let finance: FinanceModel
    @ObservationIgnored private let intelligence: IntelligenceModel

    public init(session: SessionModel, finance: FinanceModel, intelligence: IntelligenceModel) {
        self.session = session
        self.finance = finance
        self.intelligence = intelligence
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

    public var showsForecast: Bool {
        session.user != nil && intelligence.hasModel(.budgetValue)
    }

    public var suggestsTraining: Bool {
        session.user != nil && !intelligence.hasModel(.budgetValue)
            && finance.totalTransactionCount >= 2
    }

    public var isTraining: Bool { intelligence.isTraining }

    public func train() async {
        await intelligence.train()
    }

    public var forecastKey: ForecastKey {
        ForecastKey(
            userID: session.user?.id, month: session.filter.month,
            categoryIDs: Set(finance.budgets.map(\.category.id)).sorted(),
            revision: intelligence.datasetRevision,
            modelDates: intelligence.models.map(\.updateDate))
    }

    public func loadForecast() async {
        forecast = 0
        guard session.user != nil, let month = session.filter.month,
            intelligence.hasModel(.budgetValue)
        else { return }
        let prediction = await intelligence.predictExpenses(
            month: month, categoryIDs: forecastKey.categoryIDs)
        guard !Task.isCancelled else { return }
        forecast = prediction
    }
}
