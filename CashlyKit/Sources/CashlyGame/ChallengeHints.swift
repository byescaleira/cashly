import CashlyDomain
import Foundation

public struct ChallengeHints: Equatable, Sendable {
    public enum Blocker: Equatable, Sendable {
        case needsCategories, needsHistory, needsLastMonth, needsBudget, needsTags, alreadyPlanned
    }

    public static let historyMonths = 3

    public let monthlyAverage: [String: Int64]
    public let lastMonth: [String: Int64]
    public let weeklyAverage: Int64
    public let weeklyBudget: Int64
    public let monthBudget: Int64
    public let hasCategories: Bool
    public let hasTags: Bool
    public let isFullyPlanned: Bool

    public var biggestLastMonth: String? {
        lastMonth.filter { $0.value > 0 }
            .max { ($0.value, $1.key) < ($1.value, $0.key) }?.key
    }

    public var busiestCategory: String? {
        monthlyAverage.filter { $0.value > 0 }
            .max { ($0.value, $1.key) < ($1.value, $0.key) }?.key
    }

    public func blocker(for kind: Challenge.Kind) -> Blocker? {
        if kind.choosesCategory && !hasCategories { return .needsCategories }
        switch kind {
        case .belowAverage: return weeklyAverage > 0 ? nil : .needsHistory
        case .cutBiggest: return biggestLastMonth == nil ? .needsLastMonth : nil
        case .weeklyBudget, .blueMonth, .allBudgetsBlue: return monthBudget > 0 ? nil : .needsBudget
        case .tagWeek: return hasTags ? nil : .needsTags
        case .planEveryCategory: return isFullyPlanned ? .alreadyPlanned : nil
        default: return nil
        }
    }

    public func cutTarget(for categoryID: String?) -> Int64 {
        let previous = categoryID.flatMap { lastMonth[$0] } ?? 0
        return previous - previous * Challenge.cutPercent / 100
    }
}

extension ChallengeHints {
    init(_ snapshot: GameSnapshot) {
        let current = snapshot.ledger.currentMonth
        let today = snapshot.day(snapshot.today)
        let months = (1...Self.historyMonths).map { current.adding(months: -$0) }
            .filter { snapshot.ledger.hasActivity(in: $0) }
        var totals: [String: Int64] = [:]
        for month in months {
            for posting in snapshot.ledger.postings(in: month) where posting.isExpense {
                totals[posting.categoryID, default: 0] += posting.minorUnits
            }
        }
        let previous = current.adding(months: -1)
        let used = snapshot.spentCategories(in: current)
        let planned = snapshot.budgetedCategories(in: current)
        monthlyAverage = totals.mapValues { $0 / Int64(max(months.count, 1)) }
        lastMonth = snapshot.ledger.postings(in: previous).filter(\.isExpense)
            .reduce(into: [:]) { $0[$1.categoryID, default: 0] += $1.minorUnits }
        weeklyAverage = snapshot.weeklyAverage(before: today)
        weeklyBudget = snapshot.weeklyShare(of: current)
        monthBudget = snapshot.ledger.budgeted(in: current)
        hasCategories = !snapshot.ledger.categories.isEmpty
        hasTags = !snapshot.ledger.tags.isEmpty
        isFullyPlanned = !planned.isEmpty && used.isSubset(of: planned)
    }
}
