import CashlyAnalytics
import CashlyDomain
import CashlyGame
import Foundation

struct GameFixture {
    let owner = User(id: "owner", name: "Ana", photo: "1")
    var transactions: [Transaction] = []
    var events: [GameEvent] = []
    var budgets: [Budget] = []
    var today: Date
    var guideCount = 0

    init(today: Int, month: Int = 10) {
        self.today = Self.date(today, month: month)
    }

    var market: CashlyDomain.Category {
        CashlyDomain.Category(
            id: "market", user: owner, name: "Market", color: "C2602A", icon: "cart.fill")
    }

    static func date(_ day: Int, month: Int = 10, hour: Int = 12, minute: Int = 0) -> Date {
        CashlyCalendar.current.date(
            from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))
            ?? .now
    }

    mutating func spend(_ cents: Int64, day: Int, month: Int = 10, id: String? = nil) {
        let id = id ?? "t\(transactions.count)"
        let date = Self.date(day, month: month)
        transactions.append(
            Transaction(
                id: id, participants: [], category: market, money: Money(minorUnits: cents),
                date: date, summary: id, status: .settled, splitMode: nil, splitValue: nil,
                paymentsPlan: nil))
        events.append(GameEvent(kind: .transactionRecorded, date: date, value: id))
    }

    mutating func track(days: ClosedRange<Int>, month: Int = 10) {
        for day in days { event(.noSpendDay, day: day, month: month) }
    }

    mutating func event(
        _ kind: GameEvent.Kind, day: Int, month: Int = 10, value: String = "", count: Int = 0
    ) {
        events.append(
            GameEvent(kind: kind, date: Self.date(day, month: month), value: value, count: count))
    }

    mutating func budget(_ cents: Int64, month: Int) {
        guard let yearMonth = YearMonth(year: 2026, month: month) else { return }
        budgets.append(
            Budget(
                id: "b\(month)", money: Money(minorUnits: cents), category: market,
                month: yearMonth, summary: ""))
    }

    var snapshot: GameSnapshot {
        GameSnapshot(
            userID: owner.id,
            ledger: LedgerSnapshot(
                transactions: transactions, categories: [market], tags: [], budgets: budgets,
                revision: "r", today: today),
            transactions: transactions, events: events, guideCount: guideCount)
    }

    var progress: GameProgress { GameEngine.progress(snapshot) }

    func achievement(_ achievement: Achievement) -> AchievementState? {
        progress.achievements.first { $0.achievement == achievement }
    }
}
