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
        #expect(model.footer.contains("desligadas"))
    }

    @Test func pendingTransactionsBecomeReminders() async throws {
        let scheduler = FakeScheduler(status: .allowed)
        let model = NotificationsModel(defaults: defaults, scheduler: scheduler)
        let database = try CashlyDatabase.open(inMemory: true)
        let owner = User(id: "owner", name: "Perfil", photo: "1")
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
        #expect(reminders.first?.title == "Conta a pagar hoje")
        #expect(reminders.first?.body.hasPrefix("Aluguel · ") == true)

        await model.schedulePayments(for: nil, repositories: repositories)
        #expect(await scheduler.scheduled["payment."]?.isEmpty == true)
    }
}
