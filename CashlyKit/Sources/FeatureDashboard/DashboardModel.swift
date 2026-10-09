import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class DashboardModel {
    public struct Availability: Equatable {
        public let budgeted: Double
        public let available: Double
        public let remainingRatio: Double
        public let usage: BudgetUsage
    }

    public struct Comparison: Equatable {
        public let planned: Double
        public let spent: Double
        public let ratio: Double
    }

    public struct SyncKey: Hashable {
        let categories: [String]
        let tags: [String]
        let transactions: [String]
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
    public var availableCategory: CashlyDomain.Category?
    public var highlightedTransaction = 0
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
        SyncKey(
            categories: finance.categories.map(\.id), tags: finance.tags.map(\.id),
            transactions: finance.biggestTransactions.map(\.id))
    }

    public func sync() {
        comparedCategory =
            finance.categories.first { $0.id == comparedCategory?.id } ?? finance.categories.first
        availableCategory =
            finance.categories.first { $0.id == availableCategory?.id } ?? finance.categories.first
        selectedTag = finance.tags.first { $0.id == selectedTag?.id } ?? finance.tags.first
        highlightedTransaction = 0
    }

    public var totalAvailable: Double { finance.budgetsAmount - finance.expensesAmount }

    public func availability(of category: CashlyDomain.Category) -> Availability {
        let budgeted = finance.budgetsAmount(for: category)
        let usage = finance.categoryUsage(category: category)
        return Availability(
            budgeted: budgeted, available: budgeted - finance.expensesAmount(for: category),
            remainingRatio: 1 - usage.ratio, usage: usage)
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

    public func billing(of transaction: CashlyDomain.Transaction) -> Money {
        transaction.billingMoney(in: session.filter.month)
    }

    public var showsForecast: Bool {
        session.user != nil && intelligence.hasModel(.budgetValue)
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
