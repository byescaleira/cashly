import Foundation
import Testing

@testable import CashlyGame

struct ChallengeHabitTests {
    @Test func trackWeekNeedsEveryDay() {
        var game = GameFixture(today: 7)
        game.start("trackWeek||", day: 5)
        game.track(days: 5...6)
        #expect(game.challenge?.status == .active(progress: 2.0 / 7))
        #expect(game.challenge?.measure == ChallengeMeasure(2, of: 7, .days))
        game.today = GameFixture.date(9)
        #expect(game.challenge?.status == .failed)
        game.track(days: 7...11)
        game.today = GameFixture.date(12)
        #expect(game.challenge?.status == .completed)
    }

    @Test func taggedWeekFailsOnAnUntaggedExpense() {
        var game = GameFixture(today: 12)
        game.tag("trip")
        game.start("tagWeek||", day: 5)
        for day in 6...8 { game.spend(1_000, day: day, tags: ["trip"]) }
        #expect(game.challenge?.status == .completed)
        #expect(game.challenge?.measure == ChallengeMeasure(3, of: 3, .count))
        game.spend(500, day: 9)
        #expect(game.challenge?.status == .failed)
    }

    @Test func taggedWeekNeedsThreeExpenses() {
        var game = GameFixture(today: 9)
        game.start("tagWeek||", day: 5)
        game.spend(1_000, day: 6, tags: ["trip"])
        game.spend(1_000, day: 8, tags: ["trip"])
        #expect(game.challenge?.status == .active(progress: 4.0 / 7))
        game.today = GameFixture.date(12)
        #expect(game.challenge?.status == .failed)
    }

    @Test func sameDayFailsWhenAnExpenseIsRecordedLate() {
        var game = GameFixture(today: 12)
        game.start("sameDay||", day: 5)
        game.track(days: 5...11)
        game.spend(2_000, day: 6)
        #expect(game.challenge?.status == .completed)
        game.spend(1_000, day: 7, recordedOn: 8)
        #expect(game.challenge?.status == .failed)
    }

    @Test func sameDayIgnoresOldExpensesRecordedNow() {
        var game = GameFixture(today: 12)
        game.start("sameDay||", day: 5)
        game.track(days: 5...11)
        game.spend(2_000, day: 20, month: 9, id: "old")
        game.events.removeLast()
        game.event(.transactionRecorded, day: 6, value: "old")
        #expect(game.challenge?.status == .completed)
    }

    @Test func planEveryCategoryNeedsABudgetForEachUsedCategory() {
        var game = GameFixture(today: 8)
        game.spend(1_000, day: 2)
        game.spend(1_000, day: 3, category: game.cafe)
        game.budget(50_000, month: 10)
        game.start("planEveryCategory||", day: 5)
        #expect(game.challenge?.status == .active(progress: 0.5))
        game.today = GameFixture.date(12)
        #expect(game.challenge?.status == .failed)
        game.budget(10_000, month: 10, category: game.cafe)
        #expect(game.challenge?.status == .completed)
        #expect(game.challenge?.measure == ChallengeMeasure(2, of: 2, .count))
    }

    @Test func weeklyBudgetIsTheWeekShareOfTheMonth() {
        var game = GameFixture(today: 12)
        game.budget(31_000, month: 10)
        game.start("weeklyBudget||", day: 5)
        game.spend(7_000, day: 11, hour: 23)
        #expect(game.challenge?.status == .completed)
        #expect(game.challenge?.measure == ChallengeMeasure(7_000, of: 7_000, .money))
        game.spend(1, day: 5, hour: 0)
        #expect(game.challenge?.status == .failed)
    }

    @Test func blueMonthReportsTheScore() {
        var game = GameFixture(today: 1, month: 11)
        game.budget(100_000, month: 10)
        game.start("blueMonth||", day: 2)
        game.spend(10_000, day: 15)
        #expect(game.challenge?.status == .completed)
        #expect(game.challenge?.measure.target == Int64(GameEngine.blueScore))
    }

    @Test func everyBudgetInTheBlueFailsAsSoonAsOneIsOver() {
        var game = GameFixture(today: 20)
        game.budget(10_000, month: 10)
        game.budget(5_000, month: 10, category: game.cafe)
        game.start("allBudgetsBlue||", day: 2)
        game.spend(9_000, day: 10)
        game.spend(5_000, day: 11, category: game.cafe)
        #expect(game.challenge?.measure == ChallengeMeasure(2, of: 2, .count))
        game.today = GameFixture.date(1, month: 11)
        #expect(game.challenge?.status == .completed)
        game.spend(1, day: 12, category: game.cafe)
        #expect(game.challenge?.status == .failed)
    }

    @Test func everyBudgetInTheBlueFailsWithoutBudgets() {
        var game = GameFixture(today: 1, month: 11)
        game.start("allBudgetsBlue||", day: 2)
        #expect(game.challenge?.status == .failed)
    }
}

struct ChallengeHintsTests {
    @Test func freshProfileBlocksChallengesThatNeedHistory() {
        let hints = GameFixture(today: 14).progress.challengeHints
        #expect(hints.blocker(for: .belowAverage) == .needsHistory)
        #expect(hints.blocker(for: .cutBiggest) == .needsLastMonth)
        #expect(hints.blocker(for: .weeklyBudget) == .needsBudget)
        #expect(hints.blocker(for: .blueMonth) == .needsBudget)
        #expect(hints.blocker(for: .tagWeek) == .needsTags)
        #expect(hints.blocker(for: .noSpendWeekend) == nil)
        #expect(hints.blocker(for: .cap) == nil)
    }

    @Test func historyFeedsSuggestions() {
        var game = GameFixture(today: 14)
        game.spend(30_000, day: 10, month: 7)
        game.spend(60_000, day: 10, month: 9)
        game.spend(20_000, day: 12, month: 9, category: game.cafe)
        game.spend(8_000, day: 2)
        game.budget(31_000, month: 10)
        let hints = game.progress.challengeHints
        #expect(hints.monthlyAverage["market"] == 45_000)
        #expect(hints.biggestLastMonth == "market")
        #expect(hints.busiestCategory == "market")
        #expect(hints.cutTarget(for: "market") == 48_000)
        #expect(hints.weeklyAverage == 2_000)
        #expect(hints.weeklyBudget == 7_000)
        #expect(hints.isFullyPlanned)
        #expect(hints.blocker(for: .planEveryCategory) == .alreadyPlanned)
        #expect(hints.blocker(for: .belowAverage) == nil)
    }

    @Test func recentChallengesListFinishedOnesNewestFirst() {
        var game = GameFixture(today: 20)
        game.start("noSpendWeek|market|", day: 1)
        game.start("everyDay||", day: 9)
        game.start("noSpendWeekend||", day: 12)
        game.event(.challengeAbandoned, day: 13)
        let recent = game.progress.recentChallenges
        #expect(recent.map(\.challenge.kind) == [.everyDay, .noSpendWeek])
        #expect(recent.map(\.status) == [.failed, .completed])
    }
}
