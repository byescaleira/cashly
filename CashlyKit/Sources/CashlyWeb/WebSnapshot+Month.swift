import CashlyDomain
import Foundation

extension WebSnapshot.Month {
    public static let paceSlack = 0.1

    public init(month: YearMonth, today: Date, planned: Money, spent: Money, income: Money) {
        let calendar = CashlyCalendar.current
        let day = min(max(calendar.component(.day, from: today), 1), month.dayCount)
        let available = planned.minorUnits - spent.minorUnits
        let used = planned.minorUnits > 0 ? BudgetUsage(spent: spent, budgeted: planned).ratio : 0
        let elapsed = Double(day) / Double(month.dayCount)
        let daysLeft = Int64(month.dayCount - day + 1)
        let pace: WebSnapshot.Pace =
            planned.minorUnits <= 0
            ? .onTrack
            : used >= 1 ? .over : used > elapsed + Self.paceSlack ? .ahead : .onTrack
        let perDay = planned.minorUnits > 0 ? max(available, 0) / daysLeft : 0
        self.init(
            start: WebDay.string(month.startDate),
            end: WebDay.string(
                calendar.date(byAdding: .day, value: month.dayCount - 1, to: month.startDate)
                    ?? month.startDate),
            today: WebDay.string(today), planned: planned.doubleValue,
            spent: spent.doubleValue, income: income.doubleValue,
            available: Money(minorUnits: available).doubleValue, usedRatio: Self.rounded(used),
            elapsedRatio: Self.rounded(elapsed), pace: pace,
            perDay: Money(minorUnits: perDay).doubleValue)
    }

    static func rounded(_ ratio: Double) -> Double {
        (ratio * 100).rounded() / 100
    }
}

enum WebDay {
    static func string(_ date: Date) -> String {
        let parts = CashlyCalendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 1, parts.month ?? 1, parts.day ?? 1)
    }
}
