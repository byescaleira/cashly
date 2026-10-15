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

    @Test(arguments: [
        "noSpendWeek|market|", "cap|market|60000", "blueMonth||", "everyDay||",
        "lessThanLastMonth|market|",
    ])
    func legacyCodesStillDecode(code: String) {
        #expect(Challenge(code: code)?.code == code)
    }

    @Test func newCodesValidateTheirParameters() {
        #expect(Challenge(code: "cutBiggest||") == nil)
        #expect(
            Challenge(code: "cutBiggest|market|")
                == Challenge(kind: .cutBiggest, categoryID: "market"))
        #expect(Challenge(code: "noSpendWeekend||") == Challenge(kind: .noSpendWeekend))
        #expect(Challenge(code: "tagWeek") == Challenge(kind: .tagWeek))
    }

    @Test func catalogHasFourThemesOfFour() {
        #expect(Challenge.Kind.allCases.count == 16)
        for theme in Challenge.Theme.allCases {
            let kinds = Challenge.Kind.kinds(in: theme)
            #expect(kinds.count == 4)
            #expect(Set(kinds.map(\.difficulty)).count >= 2)
        }
        #expect(Challenge.Kind.allCases.allSatisfy { (75...300).contains($0.xp) })
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
