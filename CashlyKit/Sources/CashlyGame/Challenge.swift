import CashlyDomain
import Foundation

public struct Challenge: Hashable, Sendable {
    public enum Kind: String, CaseIterable, Sendable {
        case noSpendWeekend, quietDays, noSpendWeek, weekendLighter
        case belowAverage, cap, lessThanLastMonth, cutBiggest
        case trackWeek, tagWeek, sameDay, everyDay
        case planEveryCategory, weeklyBudget, blueMonth, allBudgetsBlue
    }

    public enum Theme: CaseIterable, Sendable {
        case spendLess, limits, habits, budgets
    }

    public enum Length: Sendable {
        case weekend, week, month
    }

    public enum Difficulty: Int, CaseIterable, Comparable, Sendable {
        case easy, medium, hard

        public static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public static let weekDays = 7
    public static let quietDayTarget = 3
    public static let taggedTarget = 3
    public static let averageWeeks = 4
    public static let cutPercent: Int64 = 20

    public let kind: Kind
    public let categoryID: String?
    public let limit: Int64?

    public init(kind: Kind, categoryID: String? = nil, limit: Int64? = nil) {
        self.kind = kind
        self.categoryID = categoryID
        self.limit = limit
    }

    public init?(code: String) {
        let parts = code.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard let first = parts.first, let kind = Kind(rawValue: first) else { return nil }
        let category = parts.count > 1 && !parts[1].isEmpty ? parts[1] : nil
        let limit = parts.count > 2 ? Int64(parts[2]) : nil
        guard !kind.needsCategory || category != nil, !kind.needsLimit || limit != nil else {
            return nil
        }
        self.init(kind: kind, categoryID: category, limit: limit)
    }

    public var code: String {
        [kind.rawValue, categoryID ?? "", limit.map(String.init) ?? ""].joined(separator: "|")
    }
}

extension Challenge.Kind {
    public static func kinds(in theme: Challenge.Theme) -> [Challenge.Kind] {
        allCases.filter { $0.theme == theme }
    }

    public var theme: Challenge.Theme {
        switch self {
        case .noSpendWeekend, .quietDays, .noSpendWeek, .weekendLighter: .spendLess
        case .belowAverage, .cap, .lessThanLastMonth, .cutBiggest: .limits
        case .trackWeek, .tagWeek, .sameDay, .everyDay: .habits
        case .planEveryCategory, .weeklyBudget, .blueMonth, .allBudgetsBlue: .budgets
        }
    }

    public var length: Challenge.Length {
        switch self {
        case .noSpendWeekend: .weekend
        case .cap, .lessThanLastMonth, .cutBiggest, .everyDay, .blueMonth, .allBudgetsBlue: .month
        case .quietDays, .noSpendWeek, .weekendLighter, .belowAverage, .trackWeek, .tagWeek,
            .sameDay, .planEveryCategory, .weeklyBudget:
            .week
        }
    }

    public var difficulty: Challenge.Difficulty {
        switch self {
        case .noSpendWeekend, .quietDays, .trackWeek, .tagWeek, .planEveryCategory: .easy
        case .cutBiggest, .everyDay, .blueMonth, .allBudgetsBlue: .hard
        case .noSpendWeek, .weekendLighter, .belowAverage, .cap, .lessThanLastMonth, .sameDay,
            .weeklyBudget:
            .medium
        }
    }

    public var xp: Int {
        switch self {
        case .noSpendWeekend, .trackWeek, .planEveryCategory: 75
        case .quietDays, .noSpendWeek, .tagWeek: 100
        case .weeklyBudget: 125
        case .weekendLighter, .belowAverage, .cap, .lessThanLastMonth, .sameDay: 150
        case .blueMonth: 200
        case .cutBiggest, .allBudgetsBlue: 250
        case .everyDay: 300
        }
    }

    public var needsCategory: Bool {
        self == .noSpendWeek || self == .cap || self == .lessThanLastMonth || self == .cutBiggest
    }

    public var choosesCategory: Bool { needsCategory && self != .cutBiggest }

    public var needsLimit: Bool { self == .cap }

    public var measuresUsage: Bool {
        switch self {
        case .cap, .lessThanLastMonth, .cutBiggest, .belowAverage, .weeklyBudget: true
        default: false
        }
    }

    public func period(startingAt start: Date, calendar: Calendar) -> DateInterval {
        let day = calendar.startOfDay(for: start)
        let month = YearMonth(start)
        let monthEnd = month.adding(months: 1).startDate
        switch length {
        case .weekend:
            let weekday = calendar.component(.weekday, from: day)
            let offset = weekday == 1 ? -1 : 7 - weekday
            let saturday = calendar.date(byAdding: .day, value: offset, to: day) ?? day
            let end = calendar.date(byAdding: .day, value: 2, to: saturday) ?? monthEnd
            return DateInterval(start: max(day, saturday), end: end)
        case .week:
            let end = calendar.date(byAdding: .day, value: Challenge.weekDays, to: day) ?? monthEnd
            return DateInterval(start: day, end: end)
        case .month:
            return DateInterval(start: self == .everyDay ? day : month.startDate, end: monthEnd)
        }
    }
}
