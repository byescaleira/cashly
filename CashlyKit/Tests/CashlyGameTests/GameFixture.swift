import CashlyAnalytics
import CashlyDomain
import Foundation

@testable import CashlyGame

struct GameFixture {
    let owner = User(id: "owner", name: "Ana")
    var transactions: [Transaction] = []
    var events: [GameEvent] = []
    var budgets: [Budget] = []
    var tags: [Tag] = []
    var today: Date
    var guideCount = 0

    init(today: Int, month: Int = 10) {
        self.today = Self.date(today, month: month)
    }

    var market: CashlyDomain.Category {
        CashlyDomain.Category(
            id: "market", user: owner, name: "Market", color: "C2602A", icon: "cart.fill")
    }

    var cafe: CashlyDomain.Category {
        CashlyDomain.Category(
            id: "cafe", user: owner, name: "Cafe", color: "2A60C2", icon: "cup.and.saucer.fill")
    }

    static func date(_ day: Int, month: Int = 10, hour: Int = 12, minute: Int = 0) -> Date {
        CashlyCalendar.current.date(
            from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))
            ?? .now
    }

    mutating func spend(
        _ cents: Int64, day: Int, month: Int = 10, id: String? = nil, hour: Int = 12,
        category: CashlyDomain.Category? = nil, tags: Set<String> = [], recordedOn: Int? = nil
    ) {
        let id = id ?? "t\(transactions.count)"
        let date = Self.date(day, month: month, hour: hour)
        transactions.append(
            Transaction(
                id: id, participants: [], category: category ?? market,
                money: Money(minorUnits: cents), date: date, summary: id, status: .settled,
                splitMode: nil, splitValue: nil, paymentsPlan: nil, tagIDs: tags))
        let recorded = recordedOn.map { Self.date($0, month: month, hour: 20) } ?? date
        events.append(GameEvent(kind: .transactionRecorded, date: recorded, value: id))
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

    mutating func budget(
        _ cents: Int64, month: Int, category: CashlyDomain.Category? = nil
    ) {
        guard let yearMonth = YearMonth(year: 2026, month: month) else { return }
        let category = category ?? market
        budgets.append(
            Budget(
                id: "b\(month)-\(category.id)", money: Money(minorUnits: cents),
                category: category, month: yearMonth, summary: ""))
    }

    mutating func tag(_ id: String) {
        tags.append(Tag(id: id, user: owner, name: id, color: "C2602A", icon: "tag"))
    }

    mutating func start(_ code: String, day: Int, month: Int = 10, hour: Int = 12) {
        events.append(
            GameEvent(
                kind: .challengeStarted, date: Self.date(day, month: month, hour: hour),
                value: code))
    }

    var challenge: ChallengeState? { ChallengeState.all(in: snapshot).last }

    var snapshot: GameSnapshot {
        GameSnapshot(
            userID: owner.id,
            ledger: LedgerSnapshot(
                transactions: transactions, categories: [market, cafe], tags: tags,
                budgets: budgets,
                revision: "r", today: today),
            transactions: transactions, events: events, guideCount: guideCount)
    }

    var progress: GameProgress { GameEngine.progress(snapshot) }

    func achievement(_ achievement: Achievement) -> AchievementState? {
        progress.achievements.first { $0.achievement == achievement }
    }
}
