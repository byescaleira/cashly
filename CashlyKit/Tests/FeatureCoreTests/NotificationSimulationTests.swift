import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

private actor RecordingScheduler: NotificationScheduling {
    var current: NotificationStatus
    var scheduled: [Reminder] = []
    var delivered: [Reminder] = []
    var captureGroups: [CaptureActionGroup] = []
    var badge = -1

    init(status: NotificationStatus) {
        current = status
    }

    func status() -> NotificationStatus { current }

    func requestAuthorization() -> Bool {
        current = .allowed
        return true
    }

    func replace(prefix: String, with reminders: [Reminder]) {
        scheduled += reminders
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
struct NotificationSimulationTests {
    private let owner = User(id: "owner", name: "Ana")
    private let today = Date(timeIntervalSince1970: 1_790_000_000)

    private func simulation(status: NotificationStatus = .allowed) async throws -> (
        NotificationSimulation, RecordingScheduler, Repositories
    ) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        let market = CashlyDomain.Category(
            id: "market", user: owner, name: "Mercado", color: "C2602A", icon: "cart")
        try await repositories.categories.save(market)
        try await repositories.budgets.save(
            Budget(
                id: "b-market", money: Money(minorUnits: 50_000), category: market,
                month: YearMonth(today), summary: "Mercado do mês"))
        let due = try #require(CashlyCalendar.current.date(byAdding: .day, value: 3, to: today))
        try await repositories.transactions.save(
            Transaction(
                id: "rent", participants: [], category: market, money: Money(minorUnits: 150_000),
                date: due, summary: "Aluguel", status: .pendingToPay, splitMode: nil,
                splitValue: nil, paymentsPlan: nil))
        let scheduler = RecordingScheduler(status: status)
        let today = today
        let simulation = NotificationSimulation(
            scheduler: scheduler, suiteName: UUID().uuidString, delay: 0, now: { today })
        await simulation.load(user: owner, repositories: repositories)
        return (simulation, scheduler, repositories)
    }

    @Test func billUsesThePendingTransactionWithItsActions() async throws {
        let (simulation, scheduler, _) = try await simulation()
        #expect(simulation.detail(of: .bill).hasPrefix("Aluguel · "))
        await simulation.simulate(.bill)
        let reminder = try #require(await scheduler.scheduled.first)
        #expect(reminder.id.hasPrefix("simulation.payment.owner.rent."))
        #expect(reminder.category == NotificationCategory.bill)
        #expect(reminder.userInfo[NotificationCategory.transactionKey] == "rent")
        #expect(reminder.isTimeSensitive)
        #expect(reminder.components.second != nil)
        #expect(!reminder.repeats)
        #expect(await scheduler.delivered.isEmpty)
    }

    @Test func budgetAlertsIgnoreTheOncePerMonthRule() async throws {
        let (simulation, scheduler, _) = try await simulation()
        await simulation.simulate(.budgetWarning)
        await simulation.simulate(.budgetWarning)
        await simulation.simulate(.budgetOver)
        let titles = await scheduler.scheduled.map(\.title)
        #expect(titles.count == 3)
        #expect(titles.prefix(2).allSatisfy { $0 == "Mercado at 80% of the budget" })
        #expect(titles.last == "Mercado is over budget")
        #expect(await scheduler.scheduled.allSatisfy { $0.category == NotificationCategory.budget })
    }

    @Test func weeklyAndPlanningArriveOnceInsteadOfRepeating() async throws {
        let (simulation, scheduler, _) = try await simulation()
        await simulation.simulate(.weekly)
        await simulation.simulate(.planning)
        let reminders = await scheduler.scheduled
        #expect(reminders.map(\.id) == ["simulation.weekly", "simulation.planning"])
        #expect(reminders.allSatisfy { !$0.repeats && $0.components.second != nil })
        #expect(reminders.first?.category == NotificationCategory.weekly)
    }

    @Test func captureGoesThroughTheRealCapturePath() async throws {
        let (simulation, scheduler, repositories) = try await simulation()
        await simulation.simulate(.capture)
        let pending = try await repositories.captures.captures(status: .pending)
        let capture = try #require(pending.first)
        #expect(pending.count == 1)
        #expect(capture.merchant == NotificationSimulation.sampleMerchant)
        let reminder = try #require(await scheduler.scheduled.first)
        #expect(reminder.userInfo[NotificationCategory.captureKey] == capture.id)
        #expect(
            reminder.category
                == NotificationCategory.capture(suggesting: capture.suggestedCategoryID))
        #expect(await scheduler.captureGroups.map(\.identifier).contains(reminder.category))
        #expect(await scheduler.badge == 1)
    }

    @Test func permissionAndProfileGateTheRows() async throws {
        let (simulation, _, _) = try await simulation(status: .notDetermined)
        #expect(SimulatedNotification.allCases.allSatisfy { !simulation.canSimulate($0) })
        await simulation.requestPermission()
        #expect(SimulatedNotification.allCases.allSatisfy { simulation.canSimulate($0) })
        await simulation.load(user: nil, repositories: nil)
        #expect(
            SimulatedNotification.allCases.filter { simulation.canSimulate($0) } == [.planning])
        #expect(simulation.detail(of: .bill) == "No pending bills in this profile.")
    }
}
