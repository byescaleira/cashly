import Foundation
import Testing

@testable import CashlyGame

struct ChallengeTests {
    @Test func codesRoundTrip() {
        let challenge = Challenge(kind: .cap, categoryID: "market", limit: 50_000)
        #expect(Challenge(code: challenge.code) == challenge)
        #expect(Challenge(code: "cap|market|") == nil)
        #expect(Challenge(code: "noSpendWeek||") == nil)
        #expect(Challenge(code: "unknown") == nil)
        #expect(Challenge(code: "everyDay||") == Challenge(kind: .everyDay))
    }

    @Test func noSpendWeekFailsWhenTheCategoryIsUsed() {
        var game = GameFixture(today: 5)
        game.event(.challengeStarted, day: 1, value: "noSpendWeek|market|")
        game.spend(1_000, day: 3)
        let state = ChallengeState.all(in: game.snapshot).last
        #expect(state?.status == .failed)
        #expect(game.progress.challenge == nil)
    }

    @Test func noSpendWeekCompletesAfterSevenDays() {
        var game = GameFixture(today: 9)
        game.event(.challengeStarted, day: 1, value: "noSpendWeek|market|")
        #expect(ChallengeState.all(in: game.snapshot).last?.status == .completed)
        #expect(game.progress.completedChallenges == 1)
    }

    @Test func runningChallengeReportsProgress() {
        var game = GameFixture(today: 4)
        game.event(.challengeStarted, day: 1, value: "cap|market|10000")
        game.spend(2_500, day: 2)
        #expect(game.progress.challenge?.status == .active(progress: 0.25))
    }

    @Test func abandonedChallengeStopsCounting() {
        var game = GameFixture(today: 9)
        game.event(.challengeStarted, day: 1, value: "noSpendWeek|market|")
        game.event(.challengeAbandoned, day: 2)
        #expect(ChallengeState.all(in: game.snapshot).last?.status == .abandoned)
        #expect(game.progress.completedChallenges == 0)
    }

    @Test func missedDayFailsEveryDayChallenge() {
        var game = GameFixture(today: 4)
        game.track(days: 1...1)
        game.track(days: 3...4)
        game.event(.challengeStarted, day: 1, value: "everyDay||")
        #expect(ChallengeState.all(in: game.snapshot).last?.status == .failed)
    }

    @Test func startingANewChallengeAbandonsTheRunningOne() {
        var game = GameFixture(today: 3)
        game.track(days: 1...3)
        game.event(.challengeStarted, day: 1, value: "everyDay||")
        game.event(.challengeStarted, day: 2, value: "blueMonth||")
        let states = ChallengeState.all(in: game.snapshot)
        #expect(states.map(\.status.isAbandoned) == [true, false])
    }
}

extension ChallengeState.Status {
    fileprivate var isAbandoned: Bool { self == .abandoned }
}
