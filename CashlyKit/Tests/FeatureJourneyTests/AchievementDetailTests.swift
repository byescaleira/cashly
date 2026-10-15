import CashlyData
import CashlyDomain
import CashlyGame
import FeatureCore
import Foundation
import Testing

@testable import FeatureJourney

@MainActor
struct AchievementDetailTests {
    private let owner = User(id: "owner", name: "Ana")
    private var market: CashlyDomain.Category {
        Category(id: "market", user: owner, name: "Groceries", color: "C2602A", icon: "cart.fill")
    }

    private func today() throws -> Date {
        try #require(
            CashlyCalendar.current.date(
                from: DateComponents(year: 2026, month: 10, day: 14, hour: 12)))
    }

    private func model() async throws -> (JourneyModel, CashlyDatabase) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        try await database.repositories(for: owner.id).categories.save(market)
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let now = try today()
        return (JourneyModel(session: session, defaults: defaults, now: { now }), database)
    }

    private func spend(_ cents: Int64, in database: CashlyDatabase) async throws {
        let date = try today()
        try await database.repositories(for: owner.id).transactions.save(
            Transaction(
                id: UUID().uuidString, participants: [], category: market,
                money: Money(minorUnits: cents), date: date, summary: "Market",
                status: .settled, splitMode: nil, splitValue: nil, paymentsPlan: nil))
    }

    private func state(_ achievement: Achievement, in journey: JourneyModel) throws
        -> AchievementState
    {
        try #require(journey.progress?.achievements.first { $0.achievement == achievement })
    }

    @Test func unlockingStampsTheDate() async throws {
        let (journey, database) = try await model()
        await journey.load()
        try await spend(1_000, in: database)
        await journey.load()
        let first = try state(.firstTransaction, in: journey)
        let date = try today()
        #expect(journey.unlockDates[.firstTransaction] == date)
        #expect(journey.unlockCaption(of: first) != nil)
        let detail = journey.achievementDetail(first)
        #expect(detail.rows.first?.label == "Unlocked")
        #expect(detail.rows.first?.tone == .positive)
        #expect(detail.tip == nil)
        #expect(detail.action == nil)
    }

    @Test func achievementsFoundOnFirstLoadHaveNoDate() async throws {
        let (journey, database) = try await model()
        try await spend(1_000, in: database)
        await journey.load()
        let first = try state(.firstTransaction, in: journey)
        #expect(journey.unlockDates.isEmpty)
        #expect(journey.unlockCaption(of: first) == nil)
        let row = journey.achievementDetail(first).rows.first
        #expect(row?.label == "Status")
        #expect(row?.value == "Unlocked")
    }

    @Test func lockedAchievementShowsProgressRewardTipAndAction() async throws {
        let (journey, _) = try await model()
        await journey.load()
        let streak = try state(.streak7, in: journey)
        let detail = journey.achievementDetail(streak)
        #expect(detail.title == Achievement.streak7.title)
        #expect(detail.message.contains("7"))
        #expect(detail.rows.map(\.label) == ["Progress", "Reward"])
        #expect(detail.rows.first?.value == "0 of 7")
        #expect(detail.rows.last?.tone == .tier)
        #expect(detail.tipTitle == "How to Get It")
        #expect(detail.tip == Achievement.streak7.tip)
        #expect(detail.action == .open(.addTransaction(id: nil)))
        #expect(streak.showsProgressBar)
    }

    @Test func singleStepAchievementShowsLockedStatus() async throws {
        let (journey, _) = try await model()
        await journey.load()
        let budget = try state(.firstBudget, in: journey)
        let detail = journey.achievementDetail(budget)
        #expect(detail.rows.first?.value == "Locked")
        #expect(detail.action == .open(.addBudget(id: nil, categoryID: nil, date: nil)))
        #expect(!budget.showsProgressBar)
    }

    @Test func secretAchievementKeepsItsCriterionHidden() async throws {
        let (journey, _) = try await model()
        await journey.load()
        let answer = try state(.theAnswer, in: journey)
        let detail = journey.achievementDetail(answer)
        #expect(detail.title == "Secret")
        #expect(detail.message != Achievement.theAnswer.detail)
        #expect(detail.rows.map(\.value) == ["Secret"])
        #expect(detail.tipTitle == "Clue")
        #expect(detail.tip == Achievement.theAnswer.clue)
        #expect(detail.action == nil)
        #expect(!answer.showsProgressBar)
    }

    @Test func unlockedSecretRevealsItself() async throws {
        let (journey, database) = try await model()
        await journey.load()
        try await spend(4_200, in: database)
        await journey.load()
        let answer = try state(.theAnswer, in: journey)
        let detail = journey.achievementDetail(answer)
        #expect(detail.title == Achievement.theAnswer.title)
        #expect(detail.message == Achievement.theAnswer.detail)
        #expect(detail.rows.map(\.label) == ["Unlocked", "Reward"])
    }

    @Test func unlockedStepPointsToTheNextInItsSeries() async throws {
        let (journey, _) = try await model()
        await journey.load()
        #expect(journey.nextInSeries(after: .streak7)?.achievement == .streak30)
        #expect(journey.nextInSeries(after: .blueMonth)?.achievement == .blueRun3)
        #expect(journey.nextInSeries(after: .streak365) == nil)
        #expect(journey.nextInSeries(after: .firstBudget) == nil)
        #expect(journey.nextInSeries(after: .perfectMonth) == nil)
    }

    @Test func challengeActionOnlyWithoutAnActiveChallenge() async throws {
        let (journey, _) = try await model()
        await journey.load()
        let challenge = try state(.challenges1, in: journey)
        #expect(journey.action(for: challenge) == .challenge)
        journey.chooseChallenge()
        await journey.startChallenge()
        let active = try state(.challenges1, in: journey)
        #expect(journey.action(for: active) == nil)
        #expect(journey.tip(for: active) != Achievement.challenges1.tip)
    }

    @Test func levelTipSaysHowMuchXPIsMissing() async throws {
        let (journey, _) = try await model()
        await journey.load()
        let level = try state(.level10, in: journey)
        let tip = try #require(journey.tip(for: level))
        #expect(tip.contains("XP to go."))
        #expect(tip.hasSuffix(Achievement.level10.tip))
    }

    @Test func followingAnActionRunsItAfterTheSheetCloses() async throws {
        let (journey, _) = try await model()
        await journey.load()
        let pro = ProAccess(entitlement: .none, isEnforced: false, present: {})
        journey.selected = try state(.firstBudget, in: journey)
        journey.follow(.open(.budgets))
        #expect(journey.selected == nil)
        var opened: [Route] = []
        journey.performPendingAction(pro: pro, open: { opened.append($0) }, guide: { _ in })
        #expect(opened == [.budgets])
        #expect(journey.pendingAction == nil)
        journey.follow(.challenge)
        journey.performPendingAction(pro: pro, open: { _ in }, guide: { _ in })
        #expect(journey.isChoosingChallenge)
    }

    @Test func guidesGoToNavigationAndTheProActionOpensThePaywall() async throws {
        let (journey, _) = try await model()
        var presented = 0
        var guides: [Guide] = []
        let pro = ProAccess(entitlement: .none, isEnforced: true, present: { presented += 1 })
        journey.follow(.guide(.importSpreadsheet))
        journey.performPendingAction(pro: pro, open: { _ in }, guide: { guides.append($0) })
        #expect(guides == [.importSpreadsheet])
        journey.follow(.pro)
        journey.performPendingAction(pro: pro, open: { _ in }, guide: { guides.append($0) })
        #expect(presented == 1)
    }

    @Test func everyAchievementHasItsOwnTitleCriterionAndTip() {
        let all = Achievement.allCases
        #expect(Set(all.map(\.title)).count == all.count)
        #expect(Set(all.map(\.detail)).count == all.count)
        #expect(all.allSatisfy { !$0.tip.isEmpty })
        #expect(all.filter(\.isSecret).allSatisfy { $0.tip == $0.clue && $0.action == nil })
    }

    @Test func textsQuoteTheEngineNumbers() {
        #expect(GameEngine.blueScore == 895)
        #expect(BudgetHealth.maximumScore == 1_000)
        #expect(Achievement.tagsInUse5.detail.contains("\(Achievement.tagsInUse5.target)"))
        #expect(Achievement.splits50.detail.contains("50"))
    }

    @Test func proTimeOffersThePaywallOnlyToFreeUsersAndStaysOutOfNext() async throws {
        let (journey, _) = try await model()
        await journey.load()
        let supporter = try state(.proMonth1, in: journey)
        #expect(journey.action(for: supporter) == .pro)
        journey.isPro = true
        #expect(journey.action(for: supporter) == nil)
        #expect(!journey.nextAchievements.contains { $0.achievement.group == .pro })
        #expect(Achievement.proYear2.xp == 0)
    }
}
