import CashlyData
import CashlyDomain
import CashlyGame
import FeatureCore
import FeatureJourney
import Foundation
import Testing

@MainActor
struct JourneyNoticesTests {
    private let owner = User(id: "owner", name: "Ana", photo: "1")
    private var market: CashlyDomain.Category {
        Category(id: "market", user: owner, name: "Groceries", color: "C2602A", icon: "cart.fill")
    }

    private func date(_ day: Int, hour: Int = 12) throws -> Date {
        try #require(
            CashlyCalendar.current.date(
                from: DateComponents(year: 2026, month: 10, day: day, hour: hour)))
    }

    private func tracked(_ days: ClosedRange<Int>) throws -> [GameEvent] {
        try days.map { GameEvent(kind: .noSpendDay, date: try date($0)) }
    }

    private func progress(
        today: Date, events: [GameEvent], spending: [(Int64, Date)] = []
    ) async throws -> GameProgress {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        try await repositories.categories.save(market)
        for (cents, day) in spending {
            try await repositories.transactions.save(
                Transaction(
                    id: UUID().uuidString, participants: [], category: market,
                    money: Money(minorUnits: cents), date: day, summary: "Market",
                    status: .settled, splitMode: nil, splitValue: nil, paymentsPlan: nil))
        }
        try await repositories.game.record(events)
        let source = RepositoriesGameSource(repositories: repositories, guideCount: 0)
        return GameEngine.progress(try await source.snapshot(today: today))
    }

    private func notices(today: Date, events: [GameEvent]) async throws -> JourneyNotices {
        JourneyNotices(
            progress: try await progress(today: today, events: events), userID: owner.id,
            now: today)
    }

    private func scheduled(_ id: String, in notices: JourneyNotices) -> Reminder? {
        notices.scheduled.first { $0.id == JourneyNotificationSetting.prefix + id }
    }

    @Test func openDayWarnsTonightAndReportsTomorrow() async throws {
        let notices = try await notices(today: date(14, hour: 10), events: tracked(11...13))
        let streak = try #require(scheduled("streak", in: notices))
        #expect(streak.components.day == 14)
        #expect(streak.components.hour == JourneyNotices.streakHour)
        #expect(streak.category == NotificationCategory.journeyStreak)
        #expect(streak.title.contains("3"))
        let outcome = try #require(scheduled("outcome", in: notices))
        #expect(outcome.components.day == 15)
        #expect(outcome.components.hour == JourneyNotices.outcomeHour)
        #expect(outcome.userInfo[NotificationCategory.linkKey] == JourneyNotices.restoreLink)
    }

    @Test func doneDayMovesTheWarningToTomorrow() async throws {
        let notices = try await notices(today: date(14, hour: 10), events: tracked(11...14))
        let streak = try #require(scheduled("streak", in: notices))
        #expect(streak.components.day == 15)
        #expect(streak.title.contains("4"))
        #expect(scheduled("outcome", in: notices) == nil)
    }

    @Test func freezeTurnsTheOutcomeIntoGoodNews() async throws {
        let credit = GameEvent(kind: .freezesCredited, date: try date(10), count: 1)
        let notices = try await notices(
            today: date(14, hour: 10), events: tracked(11...13) + [credit])
        #expect(notices.progress.streak.freezes == 1)
        let outcome = try #require(scheduled("outcome", in: notices))
        #expect(outcome.userInfo[NotificationCategory.linkKey] == JourneyNotices.journeyLink)
    }

    @Test func lateEveningSkipsTonight() async throws {
        let notices = try await notices(today: date(14, hour: 21), events: tracked(11...13))
        #expect(scheduled("streak", in: notices) == nil)
        #expect(scheduled("outcome", in: notices) != nil)
    }

    @Test func noStreakOnlyAnnouncesMissions() async throws {
        let notices = try await notices(today: date(14), events: [])
        #expect(scheduled("streak", in: notices) == nil)
        #expect(scheduled("outcome", in: notices) == nil)
        let missions = try #require(scheduled("missions", in: notices))
        #expect(missions.components.day == 19)
        #expect(missions.components.hour == JourneyNotices.missionsHour)
    }

    @Test func startedMissionIsRemindedOnSunday() async throws {
        let recorded = GameEvent(kind: .transactionRecorded, date: try date(13), value: "t1")
        let notices = try await notices(today: date(14), events: tracked(12...13) + [recorded])
        let started = notices.progress.missions.contains { !$0.isCompleted && $0.value > 0 }
        let reminder = scheduled("missionsEnd", in: notices)
        #expect((reminder != nil) == started)
        if let reminder {
            #expect(reminder.components.day == 18)
            #expect(reminder.components.hour == JourneyNotices.missionsEndHour)
        }
    }

    @Test func activeChallengeIsRemindedTheDayBeforeItEnds() async throws {
        let start = GameEvent(
            kind: .challengeStarted, date: try date(14, hour: 9),
            value: Challenge(kind: .trackWeek).code)
        let notices = try await notices(today: date(14, hour: 10), events: [start])
        let reminder = try #require(scheduled("challenge", in: notices))
        #expect(reminder.components.day == 19)
        #expect(reminder.components.hour == JourneyNotices.challengeHour)
    }

    @Test func levelsAndAchievementsNeedABaseline() async throws {
        let today = try date(14, hour: 13)
        let notices = JourneyNotices(
            progress: try await progress(
                today: today, events: tracked(8...14), spending: [(1_500, today)]),
            userID: owner.id, now: today)
        let alert = "journey.alert.owner."
        let first = notices.immediate(since: nil).map(\.id)
        #expect(first.contains { $0.hasPrefix(alert + "milestone.7.") })
        #expect(!first.contains { $0.hasPrefix(alert + "level.") })
        #expect(!first.contains { $0.hasPrefix(alert + "achievement.") })
        let fresh = notices.immediate(since: JourneyBaseline(level: 0, achievements: []))
            .map(\.id)
        #expect(fresh.contains(alert + "level.\(notices.progress.level.number)"))
        #expect(fresh.contains(alert + "achievement.firstTransaction"))
        #expect(!fresh.contains(alert + "achievement.streak7"))
        let known = notices.immediate(since: notices.baseline).map(\.id)
        #expect(known.allSatisfy { $0.hasPrefix(alert + "milestone.") })
    }

    @Test func fastSpendingWarnsAboutTheChallenge() async throws {
        let today = try date(14)
        let started = try date(14, hour: 9)
        let code = Challenge(kind: .cap, categoryID: "market", limit: 30_000).code
        let notices = JourneyNotices(
            progress: try await progress(
                today: today,
                events: [GameEvent(kind: .challengeStarted, date: started, value: code)],
                spending: [(25_000, try date(10))]),
            userID: owner.id, now: today)
        let id = "journey.alert.owner.pace.\(Int(started.timeIntervalSince1970)).fast"
        #expect(notices.immediate(since: notices.baseline).map(\.id).contains(id))
    }

    @Test func finishedChallengeIsAnnouncedWhileRecent() async throws {
        let started = try date(9)
        let event = GameEvent(
            kind: .challengeStarted, date: started, value: Challenge(kind: .noSpendWeekend).code)
        let id = "journey.alert.owner.challenge.\(Int(started.timeIntervalSince1970))"
        let recent = try await notices(today: date(12, hour: 10), events: [event])
        #expect(recent.immediate(since: recent.baseline).map(\.id).contains(id))
        let late = try await notices(today: date(16, hour: 10), events: [event])
        #expect(!late.immediate(since: late.baseline).map(\.id).contains(id))
    }

    @Test func notifierDeliversOnceAndSchedules() async throws {
        let scheduler = JourneyScheduler(status: .allowed)
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let notifier = JourneyNotifier(scheduler: scheduler, defaults: defaults)
        let today = try date(14, hour: 13)
        let progress = try await progress(today: today, events: tracked(8...14))
        await notifier.review(progress, userID: owner.id, isActive: true, now: today)
        await notifier.review(progress, userID: owner.id, isActive: true, now: today)
        #expect(await scheduler.delivered.map(\.id).count == 1)
        let planned = await scheduler.scheduled[JourneyNotificationSetting.prefix] ?? []
        #expect(planned.contains { $0.id == JourneyNotificationSetting.prefix + "streak" })
    }

    @Test(arguments: [true, false])
    func pausedOrTurnedOffStaysQuiet(isPaused: Bool) async throws {
        let scheduler = JourneyScheduler(status: .allowed)
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        if !isPaused { defaults.set(false, forKey: JourneyNotificationSetting.key) }
        let notifier = JourneyNotifier(scheduler: scheduler, defaults: defaults)
        let today = try date(14, hour: 13)
        let progress = try await progress(today: today, events: tracked(8...14))
        await notifier.review(progress, userID: owner.id, isActive: !isPaused, now: today)
        #expect(await scheduler.delivered.isEmpty)
        #expect(await scheduler.scheduled[JourneyNotificationSetting.prefix]?.isEmpty == true)
    }

    @Test func settingStartsOnAndAsksBeforeTurningOn() async throws {
        let scheduler = JourneyScheduler(status: .notDetermined)
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let setting = JourneyNotificationSetting(defaults: defaults, scheduler: scheduler)
        #expect(setting.isOn)
        await setting.set(false)
        #expect(!setting.isOn)
        #expect(await scheduler.scheduled[JourneyNotificationSetting.prefix]?.isEmpty == true)
        await setting.set(true)
        #expect(setting.isOn)
        #expect(await scheduler.requests == 1)
        #expect(JourneyNotificationSetting.isOn(in: defaults))
    }
}

private actor JourneyScheduler: NotificationScheduling {
    var current: NotificationStatus
    var requests = 0
    var scheduled: [String: [Reminder]] = [:]
    var delivered: [Reminder] = []

    init(status: NotificationStatus) {
        current = status
    }

    func status() -> NotificationStatus { current }

    func requestAuthorization() -> Bool {
        requests += 1
        current = .allowed
        return true
    }

    func replace(prefix: String, with reminders: [Reminder]) {
        scheduled[prefix] = reminders
    }

    func deliver(_ reminder: Reminder) {
        delivered.append(reminder)
    }

    func registerCaptureActions(_ groups: [CaptureActionGroup]) {}

    func setBadge(_ count: Int) {}
}
