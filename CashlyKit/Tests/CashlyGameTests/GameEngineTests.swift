import CashlyDomain
import Foundation
import Testing

@testable import CashlyGame

struct GameEngineTests {
    @Test func levelsFollowTheThresholdCurve() {
        #expect(GameLevel(xp: 0).number == 1)
        #expect(GameLevel(xp: 99).number == 1)
        #expect(GameLevel(xp: 100).number == 2)
        #expect(GameLevel(xp: 300).number == 3)
        #expect(GameLevel(xp: 350).xpIntoLevel == 50)
        #expect(GameLevel(xp: 10_000_000).number == GameLevel.maximum)
        #expect(GameLevel(xp: 10_000_000).progress == 1)
    }

    @Test func streakCountsConsecutiveTrackedDays() {
        var game = GameFixture(today: 5)
        game.track(days: 1...5)
        let streak = game.progress.streak
        #expect(streak.current == 5)
        #expect(streak.best == 5)
        #expect(streak.isTodayTracked)
    }

    @Test func untrackedTodayKeepsYesterdaysStreak() {
        var game = GameFixture(today: 4)
        game.track(days: 1...3)
        #expect(game.progress.streak.current == 3)
        #expect(!game.progress.streak.isTodayTracked)
    }

    @Test func missedDayResetsTheStreak() {
        var game = GameFixture(today: 4)
        game.track(days: 1...2)
        game.track(days: 4...4)
        #expect(game.progress.streak.current == 1)
        #expect(game.progress.streak.best == 2)
    }

    @Test func freezeCoversAMissedDay() {
        var game = GameFixture(today: 4)
        game.event(.freezesCredited, day: 1, value: "gift", count: 1)
        game.track(days: 1...2)
        game.track(days: 4...4)
        #expect(game.progress.streak.current == 3)
        #expect(game.progress.streak.freezes == 0)
    }

    @Test func restoreCoversARecentMissedDay() {
        var game = GameFixture(today: 4)
        game.track(days: 1...2)
        game.track(days: 4...4)
        game.event(.streakRestored, day: 4, value: "restore")
        #expect(game.progress.streak.current == 3)
    }

    @Test func longRunEarnsOneFreezePerMonth() {
        var game = GameFixture(today: 30)
        game.track(days: 1...30)
        #expect(game.progress.streak.freezes == 1)
    }

    @Test func transactionXPIsCappedPerDay() {
        var game = GameFixture(today: 3)
        for _ in 0..<12 { game.spend(100, day: 3) }
        let unlocked = game.progress.achievements.filter(\.isUnlocked).map(\.achievement)
        let achievementXP = unlocked.reduce(0) { $0 + $1.xp }
        let missionXP = game.progress.missions.filter(\.isCompleted).count * Mission.xp
        #expect(
            game.progress.xp
                == GameEngine.dailyTransactionLimit * GameEngine.transactionXP
                + GameEngine.trackingXP + achievementXP + missionXP)
    }

    @Test func healthyClosedMonthCountsAsBlue() {
        var game = GameFixture(today: 10)
        game.budget(100_000, month: 9)
        game.spend(50_000, day: 10, month: 9)
        #expect(game.achievement(.blueMonth)?.isUnlocked == true)
        #expect(game.achievement(.perfectMonth)?.isUnlocked == true)
    }

    @Test func overspentMonthIsNotBlue() {
        var game = GameFixture(today: 10)
        game.budget(100_000, month: 9)
        game.spend(105_000, day: 10, month: 9)
        #expect(game.achievement(.blueMonth)?.isUnlocked == false)
    }

    @Test func secretAchievementsUnlockFromSpecialValues() {
        var game = GameFixture(today: 31)
        game.spend(4_200, day: 31)
        #expect(game.achievement(.theAnswer)?.isUnlocked == true)
        #expect(game.achievement(.halloween)?.isUnlocked == true)
        #expect(game.achievement(.newYear)?.isUnlocked == false)
    }

    @Test func allGuidesNeedsEveryGuideOnce() {
        var game = GameFixture(today: 5)
        game.guides = ["a", "b"]
        game.event(.guideCompleted, day: 1, value: "a")
        game.event(.guideCompleted, day: 2, value: "a")
        #expect(game.achievement(.allGuides)?.isUnlocked == false)
        game.event(.guideCompleted, day: 3, value: "retired")
        #expect(game.achievement(.allGuides)?.isUnlocked == false)
        game.event(.guideCompleted, day: 4, value: "b")
        #expect(game.achievement(.allGuides)?.isUnlocked == true)
    }
}

extension GameEngineTests {
    @Test func weekShowsTrackedCoveredAndMissedDays() {
        var game = GameFixture(today: 7)
        game.event(.freezesCredited, day: 1, value: "gift", count: 1)
        game.track(days: 2...5)
        game.track(days: 7...7)
        let week = game.progress.streak.week
        #expect(week.count == Streak.weekLength)
        #expect(
            week.map(\.state) == [
                .missed, .tracked, .tracked, .tracked, .tracked, .covered, .tracked,
            ]
        )
        #expect(week.last?.date == GameFixture.date(7, hour: 0))
    }
}

struct ShopHelpTests {
    @Test func lostStreakIsRestorableForTwoDays() {
        var game = GameFixture(today: 10)
        game.track(days: 1...7)
        #expect(game.progress.streak.current == 0)
        #expect(game.progress.streak.restorable == 7)
        var old = GameFixture(today: 11)
        old.track(days: 1...7)
        #expect(old.progress.streak.restorable == 0)
    }

    @Test func firstChallengeOfTheMonthIsFreeThenRerollsAreNeeded() {
        var game = GameFixture(today: 5)
        #expect(game.progress.canStartChallenge)
        game.event(.challengeStarted, day: 1, value: "everyDay||")
        #expect(!game.progress.canStartChallenge)
        #expect(game.progress.rerolls == 0)
        game.event(.rerollsCredited, day: 2, value: "purchase", count: 3)
        #expect(game.progress.rerolls == 3)
        #expect(game.progress.canStartChallenge)
        game.event(.challengeStarted, day: 3, value: "blueMonth||")
        #expect(game.progress.rerolls == 2)
    }
}
