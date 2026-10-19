import CashlyData
import CashlyDomain
import CashlyGame
import CashlyWeb
import Foundation
import Testing

struct WebSnapshotJourneyTests {
    private func setUp(_ fixture: WebSnapshotFixture) async throws {
        let category = try await fixture.category("cat0")
        try await fixture.category("cat1")
        try await fixture.tag("tag0")
        try await fixture.budget(category, cents: 50_000)
        var events = [
            GameEvent(kind: .freezesCredited, date: try WebSnapshotFixture.day(10), count: 1)
        ]
        for day in [2, 11, 12, 13, 15] {
            let date = try WebSnapshotFixture.day(day)
            try await fixture.record(
                "spend \(day)", category, cents: 1_000, on: date, tags: day == 2 ? ["tag0"] : [])
            events.append(GameEvent(kind: .transactionRecorded, date: date))
        }
        try await fixture.repositories.game.record(events)
    }

    @Test func journeyCarriesXPTitleRecordAndFreezes() async throws {
        let fixture = try await WebSnapshotFixture()
        try await setUp(fixture)
        let snapshot = try await fixture.snapshot(includesJourney: true)
        let progress = try await fixture.progress()
        let journey = try #require(snapshot.journey)

        #expect(journey.xp == progress.xp)
        let next = try #require(progress.level.nextRankLevel)
        #expect(journey.nextTitle == GameLevel.title(for: next))
        #expect(journey.best == progress.streak.best)
        #expect(journey.best == 4)
        #expect(journey.freezes == progress.streak.freezes)
        #expect(journey.trackedToday == false)
    }

    @Test func lastSevenDaysMarkFrozenMissedAndPendingToday() async throws {
        let fixture = try await WebSnapshotFixture()
        try await setUp(fixture)
        let journey = try #require(try await fixture.snapshot(includesJourney: true).journey)
        let days = try #require(journey.days)

        #expect(days.map(\.date) == (11...17).map { "2026-10-\($0)" })
        #expect(
            days.map(\.state) == [
                .tracked, .tracked, .tracked, .frozen, .tracked, .missed, .pending,
            ])
    }

    @Test func todayCountsAsTrackedOnceRecorded() async throws {
        let fixture = try await WebSnapshotFixture()
        try await setUp(fixture)
        try await fixture.repositories.game.record([
            GameEvent(kind: .noSpendDay, date: try WebSnapshotFixture.day(17))
        ])
        let journey = try #require(try await fixture.snapshot(includesJourney: true).journey)

        #expect(journey.trackedToday == true)
        #expect(journey.days?.last?.state == .tracked)
    }

    @Test func challengeCarriesItsXPAndMeasure() async throws {
        let fixture = try await WebSnapshotFixture()
        try await setUp(fixture)
        let challenge = Challenge(kind: .cap, categoryID: "cat0", limit: 100_000)
        try await fixture.repositories.game.record([
            GameEvent(
                kind: .challengeStarted, date: try WebSnapshotFixture.day(15),
                value: challenge.code)
        ])
        let snapshot = try await fixture.snapshot(includesJourney: true)
        let state = try #require(try await fixture.progress().challenge)
        let active = try #require(snapshot.journey?.challenge)

        #expect(active.xp == Challenge.Kind.cap.xp)
        #expect(active.detail == state.caption)
        #expect(active.detail?.isEmpty == false)
    }

    @Test func missionsAreTheWeekOnesWithTheirRenewal() async throws {
        let fixture = try await WebSnapshotFixture()
        try await setUp(fixture)
        let progress = try await fixture.progress()
        let missions = try #require(
            try await fixture.snapshot(includesJourney: true).journey?.missions)

        #expect(missions.renewsOn == "2026-10-19")
        #expect(missions.items.count == Mission.perWeek)
        #expect(missions.items.map(\.title) == progress.missions.map(\.kind.title))
        #expect(missions.items.map(\.target) == progress.missions.map(\.kind.target))
        #expect(
            missions.items.map(\.done) == progress.missions.map { min($0.value, $0.kind.target) })
        #expect(missions.items.allSatisfy { $0.xp == Mission.xp })
    }

    @Test func achievementsShowTheNextThreeWithoutSecretsOrPro() async throws {
        let fixture = try await WebSnapshotFixture()
        try await setUp(fixture)
        let progress = try await fixture.progress(guides: ["first", "second"])
        let achievements = try #require(
            try await fixture.snapshot(includesJourney: true, guides: ["first", "second"])
                .journey?.achievements)

        #expect(achievements.unlocked == progress.unlockedCount)
        #expect(achievements.total == progress.achievements.count)
        #expect(achievements.next.count == GameProgress.nextAchievementCount)
        #expect(
            achievements.next.map(\.title) == progress.nextAchievements.map(\.achievement.title))
        #expect(
            achievements.next.map(\.detail)
                == progress.nextAchievements.map { $0.achievement.detail(guides: 2) })
        let shown = Set(progress.nextAchievements.map(\.achievement))
        #expect(shown.allSatisfy { !$0.isSecret && $0.group != .pro })
        for (item, state) in zip(achievements.next, progress.nextAchievements) {
            let counts = state.achievement.target > 1
            #expect(item.target == (counts ? state.achievement.target : nil))
            #expect(item.done == (counts ? min(state.value, state.achievement.target) : nil))
            #expect(item.xp == state.achievement.xp)
        }
    }

    @Test func recentAchievementsPutTheDatedOnesFirst() async throws {
        let fixture = try await WebSnapshotFixture()
        try await setUp(fixture)
        let unlocks: [Achievement: Date] = [
            .firstCategory: try WebSnapshotFixture.day(2),
            .firstTag: try WebSnapshotFixture.day(5),
        ]
        let progress = try await fixture.progress()
        let recent = try #require(
            try await fixture.snapshot(includesJourney: true, unlocks: unlocks)
                .journey?.achievements?.recent)
        let undated = try #require(
            progress.achievements.filter(\.isUnlocked).map(\.achievement).reversed()
                .first { unlocks[$0] == nil })

        #expect(recent.count == WebSnapshot.recentAchievementCount)
        #expect(
            recent.map(\.title) == [
                Achievement.firstTag.title, Achievement.firstCategory.title, undated.title,
            ])
        #expect(recent.map(\.unlockedOn) == ["2026-10-05", "2026-10-02", nil])
        #expect(recent.first?.tier == .bronze)
        #expect(recent.first?.xp == Achievement.firstTag.xp)
    }

    @Test func journeyEncodesTheOptionalFieldsThePageReads() async throws {
        let fixture = try await WebSnapshotFixture()
        try await setUp(fixture)
        let challenge = Challenge(kind: .cap, categoryID: "cat0", limit: 100_000)
        try await fixture.repositories.game.record([
            GameEvent(
                kind: .challengeStarted, date: try WebSnapshotFixture.day(15),
                value: challenge.code)
        ])
        let snapshot = try await fixture.snapshot(
            includesJourney: true, unlocks: [.firstCategory: try WebSnapshotFixture.day(2)])
        let data = try snapshot.encoded()
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let journey = try #require(object["journey"] as? [String: Any])

        for key in [
            "xp", "nextTitle", "best", "freezes", "trackedToday", "days", "missions",
            "achievements",
        ] {
            #expect(journey[key] != nil, "\(key) is missing")
        }
        let active = try #require(journey["challenge"] as? [String: Any])
        #expect(active["xp"] as? Int == Challenge.Kind.cap.xp)
        #expect(active["detail"] is String)
        let days = try #require(journey["days"] as? [[String: Any]])
        #expect(days.last?["state"] as? String == "pending")
        let missions = try #require(journey["missions"] as? [String: Any])
        #expect(missions["renewsOn"] as? String == "2026-10-19")
        let item = try #require((missions["items"] as? [[String: Any]])?.first)
        #expect(Set(item.keys) == ["title", "done", "target", "xp"])
        let achievements = try #require(journey["achievements"] as? [String: Any])
        let recent = try #require((achievements["recent"] as? [[String: Any]])?.first)
        #expect(recent["tier"] as? String == "bronze")
        #expect(recent["unlockedOn"] as? String == "2026-10-02")
        #expect(try JSONDecoder().decode(WebSnapshot.self, from: data) == snapshot)
    }

    @Test func olderJourneyWithoutTheNewFieldsStillDecodes() throws {
        let json = Data(
            """
            {"level":3,"levelTitle":"Beginner","progress":0.4,"streak":2,
             "challenge":{"title":"Spending Cap","progress":0.5,"endsOn":"2026-10-31"}}
            """.utf8)
        let journey = try JSONDecoder().decode(WebSnapshot.Journey.self, from: json)

        #expect(journey.level == 3)
        #expect(journey.xp == nil)
        #expect(journey.days == nil)
        #expect(journey.missions == nil)
        #expect(journey.achievements == nil)
        #expect(journey.challenge?.xp == nil)
        #expect(journey.challenge?.detail == nil)
    }
}
