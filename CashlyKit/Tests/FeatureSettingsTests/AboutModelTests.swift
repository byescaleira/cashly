import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

@testable import FeatureSettings

@MainActor
struct AboutModelTests {
    private let owner = User(id: "owner", name: "Ana", photo: "1")
    private var market: CashlyDomain.Category {
        Category(id: "market", user: owner, name: "Groceries", color: "C2602A", icon: "cart.fill")
    }

    private func day(_ month: Int, _ day: Int) throws -> Date {
        try #require(
            CashlyCalendar.current.date(
                from: DateComponents(year: 2026, month: month, day: day, hour: 12)))
    }

    private func model() async throws -> (AboutModel, CashlyDatabase) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        try await database.repositories(for: owner.id).categories.save(market)
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        let today = try day(10, 14)
        return (AboutModel(session: session, now: { today }), database)
    }

    private func spend(on date: Date, in database: CashlyDatabase) async throws {
        try await database.repositories(for: owner.id).transactions.save(
            Transaction(
                id: UUID().uuidString, participants: [], category: market,
                money: Money(minorUnits: 1_000), date: date, summary: "Market",
                status: .settled, splitMode: nil, splitValue: nil, paymentsPlan: nil))
    }

    @Test func notLoadedShowsPlaceholders() async throws {
        let (about, _) = try await model()
        #expect(!about.hasLoaded)
        #expect(!about.isEmpty)
        #expect(about.figures(showingJourney: true).count == 4)
    }

    @Test func emptyProfileStartsTheStory() async throws {
        let (about, _) = try await model()
        await about.load()
        #expect(about.hasLoaded)
        #expect(about.isEmpty)
        #expect(about.usage?.firstRecord == nil)
        #expect(about.figures(showingJourney: true).first?.detail == "Started this month")
    }

    @Test func countsComeFromTheProfileRecords() async throws {
        let (about, database) = try await model()
        try await spend(on: day(3, 5), in: database)
        try await spend(on: day(10, 2), in: database)
        try await spend(on: day(10, 14), in: database)
        try await spend(on: day(10, 14), in: database)
        try await spend(on: day(11, 20), in: database)
        let month = try #require(YearMonth(year: 2026, month: 10))
        try await database.repositories(for: owner.id).budgets.save(
            Budget(
                id: "october", money: Money(minorUnits: 50_000), category: market, month: month,
                summary: "October"))
        await about.load()
        let usage = try #require(about.usage)
        #expect(!about.isEmpty)
        #expect(try usage.firstRecord == day(3, 5))
        #expect(usage.monthsOfHistory == 7)
        #expect(usage.transactions == 5)
        #expect(usage.transactionsThisMonth == 3)
        #expect(usage.activeDays == 3)
        #expect(usage.activeDaysThisMonth == 2)
        #expect(usage.budgets == 1)
        #expect(usage.budgetsThisMonth == 1)
        #expect(usage.level >= 1)
        #expect(usage.xp > 0)
    }

    @Test func lastFigureFollowsTheJourneySetting() async throws {
        let (about, database) = try await model()
        try await spend(on: day(10, 14), in: database)
        await about.load()
        let level = try #require(about.usage?.level)
        let journey = about.figures(showingJourney: true)
        #expect(journey.map(\.kind) == [.history, .transactions, .days, .level])
        #expect(journey.last?.value == "Level \(level)")
        #expect(about.figures(showingJourney: false).last?.kind == .budgets)
    }

    @Test func historyReadsInMonthsThenYears() async throws {
        let (about, _) = try await model()
        #expect(about.history(months: 0) == "Started this month")
        #expect(about.history(months: 7) == "7 months of records")
        #expect(about.history(months: 30) == "2 years of records")
    }

    @Test func planFollowsTheEntitlement() async throws {
        let (about, _) = try await model()
        #expect(about.plan(for: .none) == .free)
        #expect(about.plan(for: .expired(.now)) == .free)
        #expect(about.plan(for: .trial(expires: .now)) == .trial)
        #expect(about.plan(for: .active(expires: .now)) == .pro)
        #expect(!AboutPlan.free.isPro)
        #expect(AboutPlan.trial.isPro)
    }
}
