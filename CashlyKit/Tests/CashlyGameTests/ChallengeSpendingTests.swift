import Foundation
import Testing

@testable import CashlyGame

struct ChallengeSpendingTests {
    @Test func weekendChallengeWaitsForSaturday() {
        var game = GameFixture(today: 8)
        game.start("noSpendWeekend||", day: 7)
        game.spend(2_000, day: 9)
        #expect(game.challenge?.status == .active(progress: 0))
        #expect(game.challenge?.from == GameFixture.date(10, hour: 0))
        #expect(game.challenge?.end == GameFixture.date(12, hour: 0))
        #expect(game.challenge?.measure == ChallengeMeasure(0, of: 2, .days))
        game.today = GameFixture.date(12)
        #expect(game.challenge?.status == .completed)
    }

    @Test func weekendChallengeFailsWithAnyExpense() {
        var game = GameFixture(today: 11)
        game.start("noSpendWeekend||", day: 7)
        game.spend(500, day: 11, hour: 23)
        #expect(game.challenge?.status == .failed)
    }

    @Test func weekendChallengeStartedOnSundayOnlyCountsSunday() {
        var game = GameFixture(today: 12)
        game.spend(3_000, day: 10)
        game.start("noSpendWeekend||", day: 11, hour: 9)
        game.spend(800, day: 12, hour: 0)
        #expect(game.challenge?.from == GameFixture.date(11, hour: 0))
        #expect(game.challenge?.measure.target == 1)
        #expect(game.challenge?.status == .completed)
    }

    @Test func quietDaysCompleteEarly() {
        var game = GameFixture(today: 7)
        game.start("quietDays||", day: 5)
        game.track(days: 5...7)
        #expect(game.challenge?.status == .completed)
        #expect(game.progress.challenge == nil)
        #expect(game.progress.recentChallenges.first?.challenge.kind == .quietDays)
    }

    @Test func quietDaysNeedTrackedDaysWithoutExpenses() {
        var game = GameFixture(today: 9)
        game.start("quietDays||", day: 5)
        game.track(days: 5...6)
        game.spend(1_000, day: 6)
        #expect(game.challenge?.status == .active(progress: 1.0 / 3))
        game.today = GameFixture.date(12)
        #expect(game.challenge?.status == .failed)
    }

    @Test func lighterWeekendComparesDailyAverages() {
        var game = GameFixture(today: 8)
        game.start("weekendLighter||", day: 5)
        game.spend(10_000, day: 5)
        game.spend(3_000, day: 10)
        #expect(game.challenge?.status == .active(progress: 3.0 / 7))
        game.today = GameFixture.date(12)
        #expect(game.challenge?.status == .completed)
        #expect(game.challenge?.measure == ChallengeMeasure(1_500, of: 2_000, .money))
        game.spend(2_000, day: 11)
        #expect(game.challenge?.status == .failed)
    }

    @Test func belowAverageUsesTheLastFourWeeks() {
        var game = GameFixture(today: 30)
        game.spend(20_000, day: 3)
        game.spend(20_000, day: 20)
        game.start("belowAverage||", day: 29)
        game.spend(4_000, day: 29)
        #expect(game.challenge?.status == .active(progress: 0.4))
        game.today = GameFixture.date(5, month: 11)
        #expect(game.challenge?.status == .completed)
        game.spend(6_001, day: 4, month: 11)
        #expect(game.challenge?.status == .failed)
    }

    @Test func capAllowsSpendingUpToTheLimit() {
        var game = GameFixture(today: 1, month: 11)
        game.start("cap|market|10000", day: 2)
        game.spend(10_000, day: 30)
        #expect(game.challenge?.status == .completed)
        #expect(game.challenge?.measure == ChallengeMeasure(10_000, of: 10_000, .money))
    }

    @Test func lessThanLastMonthNeedsStrictlyLess() {
        var game = GameFixture(today: 1, month: 11)
        game.spend(30_000, day: 10, month: 9)
        game.start("lessThanLastMonth|market|", day: 2)
        game.spend(20_000, day: 31, hour: 23)
        #expect(game.challenge?.status == .completed)
        game.spend(10_000, day: 15)
        #expect(game.challenge?.status == .failed)
    }

    @Test func cutBiggestTargetsEightyPercentOfLastMonth() {
        var game = GameFixture(today: 20)
        game.spend(50_000, day: 10, month: 9)
        game.start("cutBiggest|market|", day: 2)
        game.spend(40_000, day: 15)
        #expect(game.challenge?.status == .active(progress: 1))
        #expect(game.challenge?.measure == ChallengeMeasure(40_000, of: 40_000, .money))
        game.today = GameFixture.date(1, month: 11)
        #expect(game.challenge?.status == .completed)
        game.spend(1, day: 31)
        #expect(game.challenge?.status == .failed)
    }

    @Test func spendingAfterTheWindowDoesNotCount() {
        var game = GameFixture(today: 13)
        game.start("noSpendWeek|market|", day: 5)
        game.spend(900, day: 12, hour: 0)
        #expect(game.challenge?.status == .completed)
    }
}
