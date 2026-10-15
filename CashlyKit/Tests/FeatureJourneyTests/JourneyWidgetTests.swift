import CashlyData
import CashlyDomain
import CashlyGame
import FeatureCore
import FeatureJourney
import Foundation
import Testing

@MainActor
struct JourneyWidgetTests {
    private let owner = User(id: "owner", name: "Ana", photo: "1")
    private var market: CashlyDomain.Category {
        Category(id: "market", user: owner, name: "Groceries", color: "C2602A", icon: "cart.fill")
    }

    private func date(_ day: Int) throws -> Date {
        try #require(
            CashlyCalendar.current.date(
                from: DateComponents(year: 2026, month: 10, day: day, hour: 12)))
    }

    private func store() throws -> JourneySnapshotStore {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "cashly-journey-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return JourneySnapshotStore(directory: directory)
    }

    private func session() async throws -> (SessionModel, CashlyDatabase) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        try await database.repositories(for: owner.id).categories.save(market)
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        return (session, database)
    }

    private func model(
        _ session: SessionModel, store: JourneySnapshotStore, today: Date
    ) throws -> JourneyModel {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        defaults.set(false, forKey: JourneySnapshot.liveActivityKey)
        return JourneyModel(session: session, defaults: defaults, journeyStore: store) { today }
    }

    @Test func loadPublishesLevelStreakAndMissions() async throws {
        let (session, _) = try await session()
        let store = try store()
        let journey = try model(session, store: store, today: date(14))
        await journey.markNoSpendToday()
        let snapshot = try #require(try store.read())
        #expect(snapshot.userID == owner.id)
        #expect(snapshot.status == .active)
        #expect(snapshot.level.number == journey.progress?.level.number)
        #expect(snapshot.level.totalXP == journey.progress?.xp)
        #expect(snapshot.streak.current == 1)
        #expect(snapshot.streak.isTodayTracked)
        #expect(try snapshot.streak.isDone(on: date(14), calendar: CashlyCalendar.current))
        #expect(snapshot.missions.count == Mission.perWeek)
        #expect(snapshot.missions.allSatisfy { $0.xp == Mission.xp && !$0.title.isEmpty })
        #expect(snapshot.challenge == nil)
        #expect(snapshot.nextAchievement != nil)
    }

    @Test func capChallengeIsPublishedWithMoneyAndPace() async throws {
        let (session, _) = try await session()
        let store = try store()
        let journey = try model(session, store: store, today: date(14))
        await journey.load()
        journey.chooseChallenge(.cap)
        journey.draft.limit = 300
        await journey.startChallenge()
        let challenge = try #require(try store.read()?.challenge)
        #expect(challenge.outcome == .active)
        #expect(challenge.unit == .money)
        #expect(challenge.target == 30_000)
        #expect(challenge.pace == .steady)
        #expect(challenge.paceTitle != nil)
        #expect(challenge.tint == .orange)
        #expect(challenge.xp == Challenge.Kind.cap.xp)
        #expect(challenge.id.hasPrefix(Challenge.Kind.cap.rawValue + "|market|30000@"))
        #expect(try challenge.daysLeft(at: date(14), calendar: CashlyCalendar.current) == 18)
        let snapshot = try #require(try store.read())
        #expect(
            try snapshot.challengeEndingToday(at: date(14), calendar: CashlyCalendar.current) == nil
        )
        #expect(
            try snapshot.challengeEndingToday(at: date(31), calendar: CashlyCalendar.current)
                == challenge)
    }

    @Test func abandonedChallengeEndsWithoutAFinalState() async throws {
        let (session, _) = try await session()
        let store = try store()
        let journey = try model(session, store: store, today: date(14))
        await journey.load()
        journey.chooseChallenge(.everyDay)
        await journey.startChallenge()
        let id = try #require(try store.read()?.challenge?.id)
        await journey.abandonChallenge()
        let snapshot = try #require(try store.read())
        #expect(snapshot.challenge == nil)
        #expect(snapshot.finishedChallenge(id: id) == nil)
    }

    @Test func statusComesFromTheAppAndSurvivesTheJourneyTab() async throws {
        let (session, _) = try await session()
        let store = try store()
        await JourneyModel.publish(session: session, status: .paused, store: store)
        #expect(try store.read()?.status == .paused)
        let journey = try model(session, store: store, today: .now)
        await journey.load()
        #expect(try store.read()?.status == .paused)
        await JourneyModel.publish(session: session, status: .active, store: store)
        #expect(try store.read()?.status == .active)
    }

    @Test func signedOutSessionClearsTheSnapshot() async throws {
        let (session, _) = try await session()
        let store = try store()
        await JourneyModel.publish(session: session, status: .active, store: store)
        #expect(try store.read() != nil)
        let database = try CashlyDatabase.open(inMemory: true)
        let empty = SessionModel(provider: database, preference: .disabled)
        await JourneyModel.publish(session: empty, status: .active, store: store)
        #expect(try store.read() == nil)
    }
}
