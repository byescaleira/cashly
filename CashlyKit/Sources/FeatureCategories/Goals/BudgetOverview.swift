import CashlyDomain
import FeatureCore
import Foundation

public struct BudgetProgress: Identifiable, Hashable, Sendable {
    public enum Group: Int, CaseIterable, Sendable {
        case over, attention, onTrack, untouched

        var title: String {
            switch self {
            case .over: String(appLocalized: "Over the limit")
            case .attention: String(appLocalized: "Close to the limit")
            case .onTrack: String(appLocalized: "On track")
            case .untouched: String(appLocalized: "No spending yet")
            }
        }

        var detail: String {
            switch self {
            case .over: String(appLocalized: "Spending is already higher than planned.")
            case .attention: String(appLocalized: "Already used 80% or more of the plan.")
            case .onTrack: String(appLocalized: "Spending is within plan.")
            case .untouched: String(appLocalized: "No spending recorded in this period.")
            }
        }
    }

    public let budget: Budget
    public let planned: Double
    public let spent: Double

    public init(budget: Budget, planned: Double, spent: Double) {
        self.budget = budget
        self.planned = planned
        self.spent = spent
    }

    public var id: String { budget.id }
    public var remaining: Double { planned - spent }
    public var ratio: Double { planned > 0 ? spent / planned : (spent > 0 ? 1.01 : 0) }

    public var group: Group {
        if spent <= 0 { return .untouched }
        if ratio > 1 { return .over }
        if ratio >= 0.8 { return .attention }
        return .onTrack
    }

    public var usageTitle: String {
        ratio.formatted(.percent.precision(.fractionLength(0)).locale(.app))
    }

    public var remainingTitle: String {
        remaining >= 0
            ? String(appLocalized: "\(remaining.formatted(.appCurrency)) left")
            : String(appLocalized: "\(abs(remaining).formatted(.appCurrency)) over")
    }

    public var amountsTitle: String {
        String(
            appLocalized:
                "\(spent.formatted(.appCurrency)) of \(planned.formatted(.appCurrency))")
    }
}

public struct BudgetOverview: Sendable {
    public enum Pace: Sendable {
        case over, fast, steady, slow

        var title: String {
            switch self {
            case .over: String(appLocalized: "Over the plan")
            case .fast: String(appLocalized: "Spending faster than the month")
            case .steady: String(appLocalized: "On pace with the month")
            case .slow: String(appLocalized: "Spending slower than the month")
            }
        }

        var symbol: String {
            switch self {
            case .over: "exclamationmark.octagon.fill"
            case .fast: "hare.fill"
            case .steady: "checkmark.circle.fill"
            case .slow: "tortoise.fill"
            }
        }
    }

    public let items: [BudgetProgress]
    public let totalSpent: Double
    public let month: YearMonth?
    public let today: Date

    public init(items: [BudgetProgress], totalSpent: Double, month: YearMonth?, today: Date = .now)
    {
        self.items = items
        self.totalSpent = totalSpent
        self.month = month
        self.today = today
    }

    public var planned: Double { items.reduce(0) { $0 + $1.planned } }
    public var spent: Double { items.reduce(0) { $0 + $1.spent } }
    public var remaining: Double { planned - spent }
    public var ratio: Double { planned > 0 ? spent / planned : 0 }
    public var unbudgeted: Double { max(totalSpent - spent, 0) }

    public var remainingAmount: Double { abs(remaining) }

    public var headline: String {
        let planned = planned.formatted(.appCurrency)
        return remaining >= 0
            ? String(appLocalized: "available of \(planned) planned")
            : String(appLocalized: "over the \(planned) planned")
    }

    public var usageTitle: String {
        String(appLocalized: "\(usagePercent) used")
    }

    public var usagePercent: String {
        ratio.formatted(.percent.precision(.fractionLength(0)).locale(.app))
    }

    public var linkTitle: String {
        String(appLocalized: "See the \(items.count) budgets")
    }

    public var counts: [(group: BudgetProgress.Group, count: Int)] {
        groups.map { ($0.group, $0.items.count) }
    }

    public var groups: [(group: BudgetProgress.Group, items: [BudgetProgress])] {
        BudgetProgress.Group.allCases.compactMap { group in
            let items = items.filter { $0.group == group }.sorted { $0.ratio > $1.ratio }
            return items.isEmpty ? nil : (group, items)
        }
    }

    public var dayOfMonth: Int? {
        guard let month, month == YearMonth(today) else { return nil }
        return CashlyCalendar.current.component(.day, from: today)
    }

    public var daysLeft: Int? {
        guard let month, let day = dayOfMonth else { return nil }
        return month.dayCount - day + 1
    }

    public var elapsedRatio: Double? {
        guard let month, let day = dayOfMonth else { return nil }
        return Double(day) / Double(month.dayCount)
    }

    public var dailyAllowance: Double? {
        guard let daysLeft, daysLeft > 0, remaining > 0 else { return nil }
        return remaining / Double(daysLeft)
    }

    public var pace: Pace? {
        guard let elapsedRatio, planned > 0, spent > 0 else { return nil }
        if ratio > 1 { return .over }
        if ratio > elapsedRatio + 0.1 { return .fast }
        if ratio < elapsedRatio - 0.1 { return .slow }
        return .steady
    }

    public var dayTitle: String? {
        guard let month, let day = dayOfMonth else { return nil }
        return String(appLocalized: "Day \(day) of \(month.dayCount)")
    }

    public var paceDetail: String? {
        guard let elapsedRatio else { return nil }
        let elapsed = elapsedRatio.formatted(.percent.precision(.fractionLength(0)).locale(.app))
        return String(
            appLocalized: "\(usagePercent) of the plan used, \(elapsed) of the month gone.")
    }
}
