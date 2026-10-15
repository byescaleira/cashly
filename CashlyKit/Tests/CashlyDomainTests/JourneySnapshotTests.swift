import CashlyDomain
import Foundation
import Testing

struct JourneySnapshotTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ day: Int, hour: Int = 12) throws -> Date {
        try #require(
            calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour)))
    }

    private func challenge(
        _ id: String = "cap", outcome: JourneySnapshot.Challenge.Outcome = .active,
        pace: JourneySnapshot.Challenge.Pace? = .steady, ends: Date
    ) -> JourneySnapshot.Challenge {
        JourneySnapshot.Challenge(
            id: id, title: "Spending Cap", detail: "", symbol: "gauge", tint: .orange, xp: 150,
            measure: "R$ 320 of R$ 640", value: 32_000, target: 64_000, unit: .money,
            progress: 0.5, elapsed: 0.4, pace: pace, paceTitle: nil, starts: ends, ends: ends,
            outcome: outcome)
    }

    private func snapshot(
        status: JourneySnapshot.Status = .active, challenge: JourneySnapshot.Challenge? = nil,
        last: JourneySnapshot.Challenge? = nil, tracked: Bool = true, day: Date
    ) -> JourneySnapshot {
        JourneySnapshot(
            userID: "owner", status: status, currencyCode: "BRL",
            level: JourneySnapshot.Level(
                number: 3, title: "Beginner", xpIntoLevel: 150, xpForNextLevel: 300, totalXP: 450),
            streak: JourneySnapshot.Streak(
                current: 4, best: 9, freezes: 1, isTodayTracked: tracked, day: day),
            missions: [
                JourneySnapshot.Mission(
                    id: "a", title: "A", symbol: "a", value: 5, target: 5, xp: 25),
                JourneySnapshot.Mission(
                    id: "b", title: "B", symbol: "b", value: 1, target: 4, xp: 25),
            ],
            challenge: challenge, lastChallenge: last)
    }

    @Test func storeRoundTripsAndClears() throws {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "cashly-journey-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = JourneySnapshotStore(directory: directory)
        #expect(try store.read() == nil)
        let value = try snapshot(challenge: challenge(ends: date(18)), day: date(14, hour: 0))
        try store.write(value)
        #expect(try store.read() == value)
        try store.clear()
        #expect(try store.read() == nil)
    }

    @Test func figuresComeFromTheSnapshot() throws {
        let value = try snapshot(day: date(14, hour: 0))
        #expect(value.level.progress == 0.5)
        #expect(value.level.xpToNext == 150)
        #expect(value.missionsDone == 1)
        #expect(value.missions[1].progress == 0.25)
    }

    @Test func streakIsDoneOnlyOnTheSnapshotDay() throws {
        let streak = try snapshot(day: date(14, hour: 0)).streak
        #expect(try streak.isDone(on: date(14, hour: 22), calendar: calendar))
        #expect(try !streak.isDone(on: date(15, hour: 1), calendar: calendar))
    }

    @Test func daysLeftCountsDownToTheEnd() throws {
        let value = try challenge(ends: date(19, hour: 0))
        #expect(try value.daysLeft(at: date(14), calendar: calendar) == 5)
        #expect(try value.daysLeft(at: date(18, hour: 23), calendar: calendar) == 1)
        #expect(try value.daysLeft(at: date(19, hour: 1), calendar: calendar) == 0)
    }

    @Test func toneFollowsThePace() throws {
        #expect(try challenge(pace: .steady, ends: date(19)).tone == .olive)
        #expect(try challenge(pace: .fast, ends: date(19)).tone == .mustard)
        #expect(try challenge(pace: .over, ends: date(19)).tone == .rust)
        #expect(try challenge(pace: nil, ends: date(19)).tone == .orange)
    }

    @Test func streakIsAtRiskOnlyInTheEveningOfAnOpenDay() throws {
        let open = try snapshot(tracked: false, day: date(14, hour: 0))
        #expect(try open.streakRisk(at: date(14, hour: 17), calendar: calendar) == nil)
        let risk = try #require(try open.streakRisk(at: date(14, hour: 19), calendar: calendar))
        #expect(risk.current == 4)
        #expect(risk.freezes == 1)
        #expect(try risk.deadline == date(15, hour: 0))
        #expect(try risk.id == open.streakRisk(at: date(14, hour: 23), calendar: calendar)?.id)
        let done = try snapshot(day: date(14, hour: 0))
        #expect(try done.streakRisk(at: date(14, hour: 20), calendar: calendar) == nil)
        #expect(try done.streakRisk(at: date(15, hour: 20), calendar: calendar) != nil)
        let hidden = try snapshot(status: .hidden, tracked: false, day: date(14, hour: 0))
        #expect(try hidden.streakRisk(at: date(14, hour: 20), calendar: calendar) == nil)
    }

    @Test func challengeEndsTodayOnlyOnItsLastDay() throws {
        let active = try challenge(ends: date(19, hour: 0))
        let value = try snapshot(challenge: active, day: date(14))
        #expect(try value.challengeEndingToday(at: date(17), calendar: calendar) == nil)
        #expect(try value.challengeEndingToday(at: date(18, hour: 8), calendar: calendar) == active)
        #expect(try value.challengeEndingToday(at: date(19, hour: 1), calendar: calendar) == nil)
        let hidden = try snapshot(status: .hidden, challenge: active, day: date(14))
        #expect(try hidden.challengeEndingToday(at: date(18), calendar: calendar) == nil)
        let won = try snapshot(
            challenge: challenge(outcome: .completed, ends: date(19, hour: 0)), day: date(14))
        #expect(try won.challengeEndingToday(at: date(18), calendar: calendar) == nil)
    }

    @Test func finishedChallengeMatchesTheActivity() throws {
        let done = try challenge("cap@1", outcome: .completed, ends: date(19))
        let value = try snapshot(last: done, day: date(20))
        #expect(value.finishedChallenge(id: "cap@1") == done)
        #expect(value.finishedChallenge(id: "cap@2") == nil)
    }

    @Test func liveActivityPreferenceDefaultsToOn() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        #expect(JourneySnapshot.isLiveActivityEnabled(defaults))
        defaults.set(false, forKey: JourneySnapshot.liveActivityKey)
        #expect(!JourneySnapshot.isLiveActivityEnabled(defaults))
    }
}
