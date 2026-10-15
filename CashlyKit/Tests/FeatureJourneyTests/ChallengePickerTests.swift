import CashlyData
import CashlyDomain
import CashlyGame
import FeatureCore
import FeatureJourney
import Foundation
import Testing

@MainActor
struct ChallengePickerTests {
    private let owner = User(id: "owner", name: "Ana", photo: "1")
    private var market: CashlyDomain.Category {
        Category(id: "market", user: owner, name: "Groceries", color: "C2602A", icon: "cart.fill")
    }
    private var cafe: CashlyDomain.Category {
        Category(id: "cafe", user: owner, name: "Cafe", color: "2A60C2", icon: "cup.and.saucer")
    }

    private func date(_ day: Int, month: Int = 10) throws -> Date {
        try #require(
            CashlyCalendar.current.date(
                from: DateComponents(year: 2026, month: month, day: day, hour: 12)))
    }

    private func model(today: Date) async throws -> (JourneyModel, CashlyDatabase) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        try await database.repositories(for: owner.id).categories.save(market)
        try await database.repositories(for: owner.id).categories.save(cafe)
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let journey = JourneyModel(session: session, defaults: defaults, now: { today })
        return (journey, database)
    }

    private func spend(
        _ cents: Int64, on date: Date, in category: CashlyDomain.Category,
        _ database: CashlyDatabase
    ) async throws {
        try await database.repositories(for: owner.id).transactions.save(
            Transaction(
                id: UUID().uuidString, participants: [], category: category,
                money: Money(minorUnits: cents), date: date, summary: category.name,
                status: .settled, splitMode: nil, splitValue: nil, paymentsPlan: nil))
    }

    @Test func capSuggestsNinetyPercentOfTheAverage() async throws {
        let (journey, database) = try await model(today: date(14))
        try await spend(50_000, on: date(10, month: 9), in: cafe, database)
        try await spend(10_000, on: date(12, month: 9), in: market, database)
        await journey.load()
        journey.chooseChallenge(.cap)
        #expect(journey.challengePath == [.cap])
        #expect(journey.draft.categoryID == "cafe")
        #expect(journey.draft.limit == 450)
        journey.draftCategoryID = "market"
        #expect(journey.draft.limit == 90)
        #expect(journey.canStartDraft)
    }

    @Test func cutBiggestPicksLastMonthsBiggestCategory() async throws {
        let (journey, database) = try await model(today: date(14))
        try await spend(20_000, on: date(10, month: 9), in: cafe, database)
        try await spend(80_000, on: date(12, month: 9), in: market, database)
        await journey.load()
        journey.chooseChallenge()
        journey.select(.cutBiggest)
        #expect(journey.draft.categoryID == "market")
        #expect(journey.draft.challenge == Challenge(kind: .cutBiggest, categoryID: "market"))
        await journey.startChallenge()
        #expect(journey.progress?.challenge?.measure.target == 64_000)
        #expect(journey.challengeCost == .locked)
    }

    @Test func blockedChallengeCannotStart() async throws {
        let (journey, _) = try await model(today: date(14))
        await journey.load()
        journey.chooseChallenge(.weeklyBudget)
        #expect(journey.blocker(for: .weeklyBudget) == .needsBudget)
        #expect(!journey.canStartDraft)
        await journey.startChallenge()
        #expect(journey.progress?.challengeStartsThisMonth == 0)
        #expect(journey.challengeCost == .free)
    }

    @Test func weekendPeriodStartsOnSaturday() async throws {
        let (journey, _) = try await model(today: date(14))
        await journey.load()
        journey.chooseChallenge(.noSpendWeekend)
        let calendar = CashlyCalendar.current
        #expect(journey.draftPeriod.start == calendar.startOfDay(for: try date(17)))
        #expect(journey.draftPeriod.end == calendar.startOfDay(for: try date(19)))
    }

    @Test func finishedChallengesShowUpAsRecent() async throws {
        let (journey, database) = try await model(today: date(14))
        try await database.repositories(for: owner.id).game.record([
            GameEvent(kind: .challengeStarted, date: try date(1), value: "noSpendWeek|cafe|")
        ])
        await journey.load()
        #expect(journey.recentChallenges.map(\.status) == [.completed])
        #expect(journey.progress?.challenge == nil)
    }
}
