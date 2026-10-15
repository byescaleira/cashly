import CashlyData
import CashlyDomain
import CashlyGame
import FeatureCore
import FeatureJourney
import Foundation
import Testing

@MainActor
struct JourneyModelTests {
    private let owner = User(id: "owner", name: "Ana")
    private var market: CashlyDomain.Category {
        Category(id: "market", user: owner, name: "Groceries", color: "C2602A", icon: "cart.fill")
    }

    private func model() async throws -> (JourneyModel, CashlyDatabase) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        try await database.repositories(for: owner.id).categories.save(market)
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        return (JourneyModel(session: session, defaults: defaults), database)
    }

    @Test func noSpendDayStartsTheStreak() async throws {
        let (journey, _) = try await model()
        await journey.load()
        #expect(journey.progress?.streak.current == 0)
        await journey.markNoSpendToday()
        #expect(journey.progress?.streak.current == 1)
        #expect(journey.progress?.streak.isTodayTracked == true)
    }

    @Test func firstLoadDoesNotCelebrateWhatWasAlreadyThere() async throws {
        let (journey, _) = try await model()
        await journey.load()
        #expect(journey.celebrations.isEmpty)
    }

    @Test func newAchievementIsCelebratedOnce() async throws {
        let (journey, database) = try await model()
        await journey.load()
        try await database.repositories(for: owner.id).transactions.save(
            Transaction(
                id: "a", participants: [], category: market, money: Money(minorUnits: 4_200),
                date: .now, summary: "Lunch", status: .settled, splitMode: nil, splitValue: nil,
                paymentsPlan: nil))
        await journey.load()
        #expect(journey.celebrations.contains(.achievement(.firstTransaction)))
        #expect(journey.celebrations.contains(.achievement(.theAnswer)))
        while journey.celebration != nil { journey.celebration = nil }
        await journey.load()
        #expect(journey.celebrations.isEmpty)
    }

    @Test func capChallengeNeedsCategoryAndAmount() async throws {
        let (journey, _) = try await model()
        await journey.load()
        journey.chooseChallenge()
        journey.draft.kind = .cap
        #expect(journey.draft.challenge == nil)
        journey.draft.limit = 300
        await journey.startChallenge()
        #expect(
            journey.progress?.challenge?.challenge
                == Challenge(
                    kind: .cap, categoryID: "market", limit: 30_000))
        await journey.abandonChallenge()
        #expect(journey.progress?.challenge == nil)
    }
}

@MainActor
struct JourneyShopTests {
    private let owner = User(id: "owner", name: "Ana")

    @Test func secondChallengeInAMonthNeedsARerollCredit() async throws {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        try await database.repositories(for: owner.id).categories.save(
            Category(id: "market", user: owner, name: "Groceries", color: "C2602A", icon: "cart"))
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let journey = JourneyModel(session: session, defaults: defaults)
        await journey.load()
        journey.chooseChallenge()
        journey.draft.kind = .everyDay
        await journey.startChallenge()
        #expect(journey.progress?.challengeStartsThisMonth == 1)
        journey.chooseChallenge()
        journey.draft.kind = .trackWeek
        await journey.startChallenge()
        #expect(journey.progress?.challengeStartsThisMonth == 1)
        try await database.repositories(for: owner.id).game.record([
            GameEvent(kind: .rerollsCredited, value: "purchase", count: 3)
        ])
        await journey.load()
        await journey.startChallenge()
        #expect(journey.progress?.challengeStartsThisMonth == 2)
        #expect(journey.progress?.rerolls == 2)
    }
}
