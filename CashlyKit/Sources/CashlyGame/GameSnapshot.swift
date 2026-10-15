import CashlyAnalytics
import CashlyDomain
import Foundation

public struct GameSnapshot: Sendable {
    public let userID: String
    public let ledger: LedgerSnapshot
    public let transactions: [Transaction]
    public let events: [GameEvent]
    public let guideCount: Int

    public init(
        userID: String, ledger: LedgerSnapshot, transactions: [Transaction], events: [GameEvent],
        guideCount: Int
    ) {
        self.userID = userID
        self.ledger = ledger
        self.transactions = transactions
        self.events = events.sorted { $0.date < $1.date }
        self.guideCount = guideCount
    }

    public var today: Date { ledger.today }

    var calendar: Calendar { CashlyCalendar.current }

    func day(_ date: Date) -> Date { calendar.startOfDay(for: date) }

    func events(_ kind: GameEvent.Kind) -> [GameEvent] { events.filter { $0.kind == kind } }

    var trackedDays: Set<Date> {
        Set(
            events.filter { $0.kind == .transactionRecorded || $0.kind == .noSpendDay }
                .map { day($0.date) })
    }

    func spent(in month: YearMonth, categoryID: String? = nil) -> Int64 {
        ledger.postings(in: month)
            .filter { $0.isExpense && (categoryID == nil || $0.categoryID == categoryID) }
            .reduce(0) { $0 + $1.minorUnits }
    }

    func expenses(from start: Date, to end: Date, categoryID: String? = nil) -> [Posting] {
        ledger.postings.filter {
            $0.isExpense && (categoryID == nil || $0.categoryID == categoryID)
                && $0.date >= start && $0.date < end
        }
    }

    func spent(from start: Date, to end: Date, categoryID: String? = nil) -> Int64 {
        expenses(from: start, to: end, categoryID: categoryID).reduce(0) { $0 + $1.minorUnits }
    }

    func weeklyAverage(before day: Date) -> Int64 {
        let days = Challenge.weekDays * Challenge.averageWeeks
        guard let start = calendar.date(byAdding: .day, value: -days, to: day) else { return 0 }
        return spent(from: start, to: day) / Int64(Challenge.averageWeeks)
    }

    func spentCategories(in month: YearMonth) -> Set<String> {
        Set(ledger.postings(in: month).filter(\.isExpense).map(\.categoryID))
    }

    func budgetedCategories(in month: YearMonth) -> Set<String> {
        Set(budgetsByCategory(in: month).keys)
    }

    func budgetsByCategory(in month: YearMonth) -> [String: Int64] {
        ledger.budgets.filter { $0.month == month }.reduce(into: [:]) {
            $0[$1.category.id, default: 0] += $1.money.minorUnits
        }
    }

    func weeklyShare(of month: YearMonth) -> Int64 {
        ledger.budgeted(in: month) * Int64(Challenge.weekDays) / Int64(max(month.dayCount, 1))
    }

    func score(in month: YearMonth) -> Int? {
        let planned = ledger.budgeted(in: month)
        guard planned > 0 else { return nil }
        let usage = BudgetUsage(spent: Double(spent(in: month)), budgeted: Double(planned))
        return BudgetHealth(usage: usage).score
    }
}
