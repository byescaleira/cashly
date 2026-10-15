import CashlyDomain
import CashlyGame
import Foundation

struct AboutUsage: Equatable {
    static let empty = AboutUsage(
        firstRecord: nil, monthsOfHistory: 0, transactions: 0, transactionsThisMonth: 0,
        activeDays: 0, activeDaysThisMonth: 0, budgets: 0, budgetsThisMonth: 0, level: 1, xp: 0)

    let firstRecord: Date?
    let monthsOfHistory: Int
    let transactions: Int
    let transactionsThisMonth: Int
    let activeDays: Int
    let activeDaysThisMonth: Int
    let budgets: Int
    let budgetsThisMonth: Int
    let level: Int
    let xp: Int

    init(
        firstRecord: Date?, monthsOfHistory: Int, transactions: Int, transactionsThisMonth: Int,
        activeDays: Int, activeDaysThisMonth: Int, budgets: Int, budgetsThisMonth: Int,
        level: Int, xp: Int
    ) {
        self.firstRecord = firstRecord
        self.monthsOfHistory = monthsOfHistory
        self.transactions = transactions
        self.transactionsThisMonth = transactionsThisMonth
        self.activeDays = activeDays
        self.activeDaysThisMonth = activeDaysThisMonth
        self.budgets = budgets
        self.budgetsThisMonth = budgetsThisMonth
        self.level = level
        self.xp = xp
    }

    init(
        snapshot: GameSnapshot, progress: GameProgress,
        calendar: Calendar = CashlyCalendar.current
    ) {
        let today = snapshot.today
        let month = YearMonth(today)
        let past = snapshot.transactions.map(\.date).filter { $0 <= today }
        let first = past.min()
        let days = Set(past.map { calendar.startOfDay(for: $0) })
        let budgets = snapshot.ledger.budgets
        self.init(
            firstRecord: first,
            monthsOfHistory: first.map { month.months(since: YearMonth($0)) } ?? 0,
            transactions: snapshot.transactions.count,
            transactionsThisMonth: snapshot.transactions.filter { YearMonth($0.date) == month }
                .count,
            activeDays: days.count,
            activeDaysThisMonth: days.filter { YearMonth($0) == month }.count,
            budgets: budgets.count,
            budgetsThisMonth: budgets.filter { $0.month == month }.count,
            level: progress.level.number, xp: progress.xp)
    }
}
