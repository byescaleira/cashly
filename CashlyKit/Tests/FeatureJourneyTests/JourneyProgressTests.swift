import CashlyData
import CashlyDomain
import CashlyGame
import FeatureCore
import FeatureJourney
import Foundation
import Testing

@MainActor
struct JourneyProgressTests {
    private let owner = User(id: "owner", name: "Ana", photo: "1")
    private var market: CashlyDomain.Category {
        Category(id: "market", user: owner, name: "Groceries", color: "C2602A", icon: "cart.fill")
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
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let journey = JourneyModel(session: session, defaults: defaults, now: { today })
        return (journey, database)
    }

    private func spend(_ cents: Int64, on date: Date, in database: CashlyDatabase) async throws {
        try await database.repositories(for: owner.id).transactions.save(
            Transaction(
                id: UUID().uuidString, participants: [], category: market,
                money: Money(minorUnits: cents), date: date, summary: "Market", status: .settled,
                splitMode: nil, splitValue: nil, paymentsPlan: nil))
    }

    @Test func streakMilestonePointsToTheNextMark() async throws {
        let (journey, _) = try await model(today: date(14))
        await journey.load()
        #expect(journey.streakMilestone?.target == 7)
        #expect(journey.streakMilestone?.remaining == 7)
        #expect(journey.streakMilestone?.progress == 0)
        await journey.markNoSpendToday()
        #expect(journey.streakMilestone?.remaining == 6)
    }

    @Test(arguments: [(14, 5), (18, 1), (19, 7)])
    func newMissionsArriveOnMonday(day: Int, days: Int) async throws {
        let (journey, _) = try await model(today: date(day))
        #expect(journey.daysUntilNewMissions == days)
    }

    @Test func freshProfileClimbsTheFirstTitle() async throws {
        let (journey, _) = try await model(today: date(14))
        await journey.load()
        #expect(journey.levelsToNextRank == GameLevel.rankLength)
        #expect(journey.rankSteps < 1)
    }

    @Test func capChallengeComparesUsageWithTheMonth() async throws {
        let (journey, database) = try await model(today: date(14))
        await journey.load()
        journey.chooseChallenge(.cap)
        #expect(journey.isChoosingChallenge)
        #expect(journey.draft.kind == .cap)
        journey.draft.limit = 300
        await journey.startChallenge()
        let steady = try #require(journey.challengeOutlook)
        #expect(steady.pace == .steady)
        #expect(steady.daysLeft == 18)
        #expect(abs((steady.elapsed ?? 0) - 14.0 / 31) < 0.001)
        try await spend(25_000, on: date(10), in: database)
        await journey.load()
        #expect(journey.challengeOutlook?.pace == .fast)
        #expect(abs((journey.challengeOutlook?.progress ?? 0) - 25_000.0 / 30_000) < 0.001)
    }

    @Test func timeChallengeHasNoPace() async throws {
        let (journey, _) = try await model(today: date(14))
        await journey.load()
        journey.chooseChallenge(.blueMonth)
        await journey.startChallenge()
        let outlook = try #require(journey.challengeOutlook)
        #expect(outlook.pace == nil)
        #expect(outlook.isUsage == false)
        #expect(journey.challengeSuggestions.first == .noSpendWeek)
    }

    @Test func nextAchievementsAreTheClosestLockedOnes() async throws {
        let (journey, database) = try await model(today: .now)
        try await spend(1_500, on: .now, in: database)
        await journey.load()
        let next = journey.nextAchievements
        #expect(next.count == 3)
        #expect(next.allSatisfy { !$0.isUnlocked && !$0.achievement.isSecret })
        #expect(next.first?.achievement == .streak7)
        #expect(next.map(\.progress) == next.map(\.progress).sorted(by: >))
        #expect(next.first?.isStarted == true)
        #expect(journey.unlockedCount > 0)
    }
}
