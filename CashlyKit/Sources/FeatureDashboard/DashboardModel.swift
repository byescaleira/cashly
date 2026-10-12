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

    public struct SyncKey: Hashable {
        let categories: [String]
        let transactions: [String]
    }

    public var highlightedTransaction = 0
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let finance: FinanceModel

    public init(session: SessionModel, finance: FinanceModel) {
        self.session = session
        self.finance = finance
    }

    public var syncKey: SyncKey {
        SyncKey(
            categories: finance.categories.map(\.id),
            transactions: finance.biggestTransactions.map(\.id))
    }

    public func sync() {
        highlightedTransaction = 0
    }

    public var totalAvailable: Double { finance.budgetsAmount - finance.expensesAmount }

    public var totalUsage: BudgetUsage {
        BudgetUsage(spent: finance.expensesAmount, budgeted: finance.budgetsAmount)
    }

    public func availability(of category: CashlyDomain.Category) -> Availability {
        let budgeted = finance.budgetsAmount(for: category)
        let usage = finance.categoryUsage(category: category)
        return Availability(
            budgeted: budgeted, available: budgeted - finance.expensesAmount(for: category),
            remainingRatio: 1 - usage.ratio, usage: usage)
    }

    public func billing(of transaction: CashlyDomain.Transaction) -> Money {
        transaction.billingMoney(in: session.filter.month)
    }
}
