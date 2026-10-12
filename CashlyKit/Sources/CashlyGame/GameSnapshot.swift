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

    func spent(categoryID: String, from start: Date, to end: Date) -> Int64 {
        ledger.postings
            .filter {
                $0.isExpense && $0.categoryID == categoryID && $0.date >= start && $0.date < end
            }
            .reduce(0) { $0 + $1.minorUnits }
    }

    func score(in month: YearMonth) -> Int? {
        let planned = ledger.budgeted(in: month)
        guard planned > 0 else { return nil }
        let usage = BudgetUsage(spent: Double(spent(in: month)), budgeted: Double(planned))
        return BudgetHealth(usage: usage).score
    }
}
