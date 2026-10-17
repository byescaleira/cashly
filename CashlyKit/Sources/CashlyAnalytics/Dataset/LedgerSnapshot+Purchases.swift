import CashlyDomain
import Foundation

extension LedgerSnapshot {
    var startOfToday: Date { CashlyCalendar.current.startOfDay(for: today) }

    var endOfToday: Date {
        CashlyCalendar.current.date(byAdding: .day, value: 1, to: startOfToday) ?? today
    }

    func purchases(lastDays days: Int) -> [Posting] {
        let calendar = CashlyCalendar.current
        let end = endOfToday
        guard let start = calendar.date(byAdding: .day, value: 1 - days, to: startOfToday)
        else { return [] }
        return postings.filter {
            $0.isExpense && $0.installments <= 1 && $0.date >= start && $0.date < end
        }
    }

    func coveredDays(lastDays days: Int) -> Int {
        guard let first = postings.filter(\.isExpense).map(\.date).min() else { return 0 }
        let calendar = CashlyCalendar.current
        let elapsed =
            calendar.dateComponents([.day], from: calendar.startOfDay(for: first), to: startOfToday)
            .day ?? 0
        return min(days, max(elapsed + 1, 0))
    }

    func expensesByCategory(in month: YearMonth, throughDay day: Int) -> [String: [Posting]] {
        let calendar = CashlyCalendar.current
        let limit = min(day, month.dayCount)
        return Dictionary(
            grouping: postings(in: month).filter {
                $0.isExpense && calendar.component(.day, from: $0.date) <= limit
            }, by: \.categoryID)
    }
}
