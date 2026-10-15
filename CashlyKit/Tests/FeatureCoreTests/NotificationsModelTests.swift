import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

private actor FakeScheduler: NotificationScheduling {
    var current: NotificationStatus
    var grants: Bool
    var requests = 0
    var scheduled: [String: [Reminder]] = [:]
    var delivered: [Reminder] = []
    var captureGroups: [CaptureActionGroup] = []
    var badge = -1

    init(status: NotificationStatus, grants: Bool = true) {
        current = status
        self.grants = grants
    }

    func status() -> NotificationStatus { current }

    func requestAuthorization() -> Bool {
        requests += 1
        current = grants ? .allowed : .denied
        return grants
    }

    func replace(prefix: String, with reminders: [Reminder]) {
        scheduled[prefix] = reminders
    }

    func deliver(_ reminder: Reminder) {
        delivered.append(reminder)
    }

    func registerCaptureActions(_ groups: [CaptureActionGroup]) {
        captureGroups = groups
    }

    func setBadge(_ count: Int) {
        badge = count
    }
}

@MainActor
struct NotificationsModelTests {
    private let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard

    @Test func turningOnAsksPermissionOnce() async {
        let scheduler = FakeScheduler(status: .notDetermined)
        let model = NotificationsModel(defaults: defaults, scheduler: scheduler)
        await model.setPlanning(true)
        #expect(model.remindsPlanning)
        #expect(await scheduler.requests == 1)
        let planning = await scheduler.scheduled["planning"]
        #expect(planning?.first?.repeats == true)
        #expect(planning?.first?.components.day == 1)
        await model.setPlanning(false)
        #expect(await scheduler.scheduled["planning"]?.isEmpty == true)
        #expect(
            NotificationsModel(defaults: defaults, scheduler: scheduler).remindsPlanning == false)
    }

    @Test func deniedPermissionKeepsItOff() async {
        let scheduler = FakeScheduler(status: .notDetermined, grants: false)
        let model = NotificationsModel(defaults: defaults, scheduler: scheduler)
        await model.setPayments(true)
        #expect(!model.remindsPayments)
        #expect(model.status == .denied)
        #expect(model.footer.contains("turned off"))
    }

    @Test func budgetAlertsFireOncePerThresholdAndMonth() async throws {
        let scheduler = FakeScheduler(status: .allowed)
        let model = NotificationsModel(defaults: defaults, scheduler: scheduler)
        await model.setBudgets(true)
        let month = try #require(YearMonth(year: 2026, month: 10))
        func snapshot(spent: Int64) -> WidgetSnapshot {
            WidgetSnapshot(
                userID: "u", userName: "Ana", month: month, currencyCode: "BRL",
                plannedMinorUnits: 1000, spentMinorUnits: spent, incomeMinorUnits: 0,
                budgets: [
                    WidgetSnapshot.BudgetLine(
                        id: "b", categoryName: "Mercado", color: "000000", icon: "cart",
                        plannedMinorUnits: 1000, spentMinorUnits: spent)
                ])
        }
        await model.review(snapshot(spent: 500))
        #expect(await scheduler.delivered.isEmpty)
        await model.review(snapshot(spent: 850))
        await model.review(snapshot(spent: 900))
        #expect(await scheduler.delivered.count == 1)
        #expect(await scheduler.delivered.first?.title.contains("80%") == true)
        await model.review(snapshot(spent: 1200))
        await model.review(snapshot(spent: 1300))
        #expect(await scheduler.delivered.count == 2)
        #expect(await scheduler.delivered.last?.category == NotificationCategory.budget)
    }

    @Test func weeklySummaryLandsOnSundayEvening() async throws {
        let scheduler = FakeScheduler(status: .allowed)
        let model = NotificationsModel(defaults: defaults, scheduler: scheduler)
        await model.setWeekly(true)
        let month = try #require(YearMonth(year: 2026, month: 10))
        let snapshot = WidgetSnapshot(
            userID: "u", userName: "Ana", month: month, currencyCode: "BRL",
            plannedMinorUnits: 50_000, spentMinorUnits: 12_000, incomeMinorUnits: 0, budgets: [])
        await model.review(snapshot, now: Date(timeIntervalSince1970: 1_791_000_000))
        let weekly = try #require(await scheduler.scheduled["weekly"]?.first)
        #expect(weekly.components.hour == 18)
        let date = try #require(CashlyCalendar.current.date(from: weekly.components))
        #expect(CashlyCalendar.current.component(.weekday, from: date) == 1)
        await model.setWeekly(false)
        #expect(await scheduler.scheduled["weekly"]?.isEmpty == true)
    }

    @Test func pendingTransactionsBecomeReminders() async throws {
        let scheduler = FakeScheduler(status: .allowed)
        let model = NotificationsModel(defaults: defaults, scheduler: scheduler)
        let database = try CashlyDatabase.open(inMemory: true)
        let owner = User(id: "owner", name: "Perfil")
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        let category = Category(id: "c", user: owner, name: "Geral", color: "0099FF", icon: "cart")
        try await repositories.categories.save(category)
        let future = try #require(CashlyCalendar.current.date(byAdding: .day, value: 3, to: .now))
        try await repositories.transactions.save(
            Transaction(
                id: "rent", participants: [], category: category,
                money: Money(minorUnits: 150_000), date: future, summary: "Aluguel",
                status: .pendingToPay, splitMode: nil, splitValue: nil, paymentsPlan: nil))

        await model.schedulePayments(for: owner.id, repositories: repositories)
        #expect(await scheduler.scheduled.isEmpty)

        await model.setPayments(true)
        await model.schedulePayments(for: owner.id, repositories: repositories)
        let reminders = try #require(await scheduler.scheduled["payment.owner."])
        #expect(reminders.count == 1)
        #expect(reminders.first?.title == "Bill due today")
        #expect(reminders.first?.body.hasPrefix("Aluguel · ") == true)

        await model.schedulePayments(for: nil, repositories: repositories)
        #expect(await scheduler.scheduled["payment."]?.isEmpty == true)
    }

    @Test func reviewsCapturesWithCategoriesAndBadge() async throws {
        let scheduler = FakeScheduler(status: .allowed)
        let model = NotificationsModel(defaults: defaults, scheduler: scheduler)
        let database = try CashlyDatabase.open(inMemory: true)
        let owner = User(id: "owner", name: "Ana")
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        let food = CashlyDomain.Category(
            id: "food", user: owner, name: "Comida", color: "C2602A", icon: "cart")
        try await repositories.categories.save(food)
        let capture = try await repositories.captures.save(
            Capture(
                ownerID: owner.id, money: Money(minorUnits: 3290), merchant: "iFood",
                date: .now, source: .wallet, suggestedCategoryID: food.id))
        await model.reviewCaptures(for: owner, repositories: repositories, categories: [food])
        let groups = await scheduler.captureGroups
        #expect(groups.map(\.identifier) == ["cashly.capture", "cashly.capture.food"])
        #expect(groups.first?.frequent.map(\.id) == ["food"])
        #expect(groups.last?.frequent.isEmpty == true)
        #expect(await scheduler.badge == 1)
        let reminder = capture.reminder(categories: [food])
        #expect(reminder.category == "cashly.capture.food")
        #expect(reminder.userInfo[NotificationCategory.captureKey] == capture.id)
        #expect(capture.reminder(categories: []).category == "cashly.capture")
        await model.reviewCaptures(for: nil, repositories: repositories, categories: [])
        #expect(await scheduler.badge == 0)
    }
}
