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

    public struct TopSpending: Identifiable, Equatable {
        public let id: String
        public let summary: String
        public let category: String
        public let icon: String
        public let color: String
        public let date: Date
        public let amount: Double
        public let share: Double

        public var detail: String {
            "\(category) · \(date.formatted(.dateTime.day().month(.abbreviated)))"
        }
    }

    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let finance: FinanceModel

    public init(session: SessionModel, finance: FinanceModel) {
        self.session = session
        self.finance = finance
    }

    public var topSpending: [TopSpending] {
        let total = finance.expensesAmount
        return finance.biggestTransactions.map { transaction in
            let amount = billing(of: transaction).doubleValue
            return TopSpending(
                id: transaction.id, summary: transaction.summary,
                category: transaction.category.name.capitalized, icon: transaction.category.icon,
                color: transaction.category.color, date: transaction.date, amount: amount,
                share: total > 0 ? amount / total : 0)
        }
    }

    public var topSpendingShare: Double {
        min(topSpending.reduce(0) { $0 + $1.share }, 1)
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
