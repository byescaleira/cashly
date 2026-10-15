import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

@testable import FeatureStore

private actor FakeScheduler: NotificationScheduling {
    var current: NotificationStatus
    var scheduled: [String: [Reminder]] = [:]

    init(status: NotificationStatus = .allowed) {
        current = status
    }

    func status() -> NotificationStatus { current }

    func requestAuthorization() -> Bool {
        current = .allowed
        return true
    }

    func replace(prefix: String, with reminders: [Reminder]) {
        scheduled[prefix] = reminders
    }

    func deliver(_ reminder: Reminder) {}

    func registerCaptureActions(_ groups: [CaptureActionGroup]) {}

    func setBadge(_ count: Int) {}
}

@MainActor
struct StoreModelTests {
    private let owner = User(id: "owner", name: "Ana")
    private let scheduler = FakeScheduler()

    private func store(withUser: Bool = true) async throws -> (
        StoreModel, FakeStoreClient, CashlyDatabase
    ) {
        let database = try CashlyDatabase.open(inMemory: true)
        if withUser { try await database.repositories(for: nil).users.save(owner) }
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        let client = FakeStoreClient()
        client.catalog = ShopItem.allCases.map { item in
            switch item {
            case .proMonthly:
                StoreProduct(
                    id: item.id, displayPrice: "R$ 14,90", price: 14.90, period: .month,
                    trialDays: 7)
            case .proYearly:
                StoreProduct(
                    id: item.id, displayPrice: "R$ 99,90", price: 99.90, period: .year,
                    trialDays: 7)
            default: StoreProduct(id: item.id, displayPrice: "R$ 9,90")
            }
        }
        let store = StoreModel(session: session, client: client, scheduler: scheduler)
        await store.loadProducts()
        await store.refresh()
        return (store, client, database)
    }

    private func events(_ database: CashlyDatabase) async throws -> [GameEvent] {
        try await database.repositories(for: owner.id).game.events()
    }

    @Test func everyCatalogItemHasAProduct() async throws {
        let (store, _, _) = try await store()
        #expect(store.products.count == ShopItem.allCases.count)
        #expect(store.hasLoaded)
        #expect(store.price(for: .iconsAll) == "R$ 9,90")
        #expect(store.entitlement == .none)
    }

    @Test func refreshMarksTheFirstCheckAndDescribesThePlan() async throws {
        let (store, client, _) = try await store()
        #expect(store.hasRefreshed)
        #expect(store.entitlement.title == "Not Subscribed")
        #expect(store.entitlement.detail == nil)
        let ends = Date(timeIntervalSince1970: 1_800_000_000)
        client.deliver(
            StoreTransaction(
                id: 7, productID: ShopItem.proMonthly.id, expirationDate: ends, isFreeTrial: true))
        await store.refresh()
        #expect(store.entitlement == .trial(expires: ends))
        #expect(store.entitlement.title == "Free Trial")
        #expect(store.entitlement.detail?.contains("2027") == true)
    }

    @Test func buyingAnIconPackOwnsIt() async throws {
        let (store, client, _) = try await store()
        client.next = .success(StoreTransaction(id: 1, productID: ShopItem.iconsFashion.id))
        #expect(try await store.purchase(.iconsFashion) == .purchased)
        #expect(store.owned == [.iconsFashion])
        #expect(client.finished == [1])
    }

    @Test func pendingAndCancelledPurchasesOwnNothing() async throws {
        let (store, client, _) = try await store()
        client.next = .pending
        #expect(try await store.purchase(.sounds) == .pending)
        client.next = .cancelled
        #expect(try await store.purchase(.sounds) == .cancelled)
        #expect(store.owned.isEmpty)
        #expect(client.finished.isEmpty)
    }

    @Test func refundedItemsAreNotOwned() async throws {
        let (store, client, _) = try await store()
        client.deliver(StoreTransaction(id: 2, productID: ShopItem.sounds.id, revocationDate: .now))
        await store.refresh()
        #expect(store.owned.isEmpty)
    }

    @Test func freezesAreCreditedOnce() async throws {
        let (store, client, database) = try await store()
        let transaction = StoreTransaction(id: 3, productID: ShopItem.freezes3.id, quantity: 2)
        client.next = .success(transaction)
        _ = try await store.purchase(.freezes3)
        await store.handle(transaction)
        let credited = try await events(database).filter { $0.kind == .freezesCredited }
        #expect(credited.map(\.count) == [6])
        #expect(credited.first?.value == "3")
        #expect(client.finished == [3, 3])
    }

    @Test func consumableWaitsForAProfile() async throws {
        let (store, client, database) = try await store(withUser: false)
        let transaction = StoreTransaction(id: 4, productID: ShopItem.streakRestore.id)
        client.waiting = [transaction]
        await store.handle(transaction)
        #expect(client.finished.isEmpty)
        try await database.repositories(for: nil).users.save(owner)
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        let readyClient = FakeStoreClient()
        readyClient.waiting = [transaction]
        await StoreModel(session: session, client: readyClient).handle(transaction)
        #expect(readyClient.finished == [4])
        #expect(try await events(database).map(\.kind) == [.streakRestored])
    }

    @Test func subscriptionStartsAsTrialThenRenewsThenExpires() async throws {
        let (store, client, _) = try await store()
        let week = Date.now.addingTimeInterval(7 * 86_400)
        client.next = .success(
            StoreTransaction(
                id: 5, productID: ShopItem.proMonthly.id, expirationDate: week, isFreeTrial: true))
        _ = try await store.purchase(.proMonthly)
        #expect(store.entitlement == .trial(expires: week))
        #expect(store.entitlement.isActive)
        let month = week.addingTimeInterval(30 * 86_400)
        client.entitlements = [
            StoreTransaction(id: 6, productID: ShopItem.proMonthly.id, expirationDate: month)
        ]
        await store.refresh()
        #expect(store.entitlement == .active(expires: month))
        client.entitlements = []
        client.latestByProduct[ShopItem.proMonthly.id] = StoreTransaction(
            id: 6, productID: ShopItem.proMonthly.id, expirationDate: month)
        await store.refresh()
        #expect(store.entitlement == .expired(month))
        #expect(!store.entitlement.isActive)
    }

    @Test func plansLeadWithTheAnnualSaving() async throws {
        let (store, client, _) = try await store()
        #expect(store.plans.map(\.item) == [.proYearly, .proMonthly])
        #expect(store.plans.first?.savingPercent == 44)
        #expect(store.plans.first?.isBestValue == true)
        #expect(store.plans.last?.savingPercent == nil)
        #expect(store.selectedPlan == .proYearly)
        #expect(store.trialDays == nil)
        client.eligible = [ShopItem.proYearly.id, ShopItem.proMonthly.id]
        await store.loadProducts()
        #expect(store.introEligible == [.proYearly, .proMonthly])
        #expect(store.trialDays == 7)
    }

    @Test func subscribingRemindsTwoDaysBeforeTheTrialEnds() async throws {
        let (store, client, _) = try await store()
        let ends = Date.now.addingTimeInterval(7 * 86_400)
        client.next = .success(
            StoreTransaction(
                id: 8, productID: ShopItem.proYearly.id, expirationDate: ends, isFreeTrial: true))
        #expect(await store.subscribe())
        #expect(store.entitlement == .trial(expires: ends))
        let reminders = await scheduler.scheduled[TrialReminder.id]
        let fires = CashlyCalendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: ends.addingTimeInterval(-2 * 86_400))
        #expect(reminders?.map(\.components) == [fires])
        #expect(reminders?.first?.title == "Your Cashly Pro trial ends in 2 days")
    }

    @Test func paidSubscriptionsScheduleNoTrialReminder() async throws {
        let (store, client, _) = try await store()
        client.next = .success(
            StoreTransaction(
                id: 9, productID: ShopItem.proMonthly.id,
                expirationDate: .now.addingTimeInterval(30 * 86_400)))
        store.selectedPlan = .proMonthly
        #expect(await store.subscribe())
        #expect(await scheduler.scheduled.isEmpty)
    }

    @Test func restoringWithoutASubscriptionReportsIt() async throws {
        let (store, client, _) = try await store()
        #expect(await store.restoreSubscription() == false)
        #expect(client.synced)
        client.entitlements = [
            StoreTransaction(
                id: 10, productID: ShopItem.proYearly.id,
                expirationDate: .now.addingTimeInterval(86_400))
        ]
        #expect(await store.restoreSubscription())
        #expect(!store.isBuying)
    }

    @Test func buyingAnItemFollowsTheSubscriptionPath() async throws {
        let (store, client, _) = try await store()
        client.next = .pending
        #expect(await store.buy(.iconsSports) == false)
        #expect(store.isPending(.iconsSports))
        #expect(!store.isPending)
        client.next = .success(StoreTransaction(id: 11, productID: ShopItem.iconsSports.id))
        #expect(await store.buy(.iconsSports))
        #expect(store.owns(.iconsSports))
        #expect(!store.isPending(.iconsSports))
        #expect(!store.isBuying)
    }

    @Test func restoringAnItemReportsWhetherItIsOwned() async throws {
        let (store, client, _) = try await store()
        #expect(await store.restoreItem(.iconsFashion) == false)
        #expect(await store.restoreItems() == false)
        client.entitlements = [StoreTransaction(id: 12, productID: ShopItem.iconsAll.id)]
        #expect(await store.restoreItem(.iconsFashion))
        #expect(await store.restoreItems())
        #expect(client.synced)
    }

    @Test func restoreSyncsAndRefreshes() async throws {
        let (store, client, _) = try await store()
        client.entitlements = [StoreTransaction(id: 7, productID: ShopItem.iconsAll.id)]
        try await store.restore()
        #expect(client.synced)
        #expect(store.owned == [.iconsAll])
    }

    @Test func proTimeAddsUpFromThePlanHistoryAndIsRecordedOnce() async throws {
        let (store, client, database) = try await store()
        let now = Date.now
        client.past = [
            StoreTransaction(
                id: 20, productID: ShopItem.proMonthly.id,
                purchaseDate: now.addingTimeInterval(-70 * 86_400),
                expirationDate: now.addingTimeInterval(-40 * 86_400), isFreeTrial: true),
            StoreTransaction(
                id: 21, productID: ShopItem.proMonthly.id,
                purchaseDate: now.addingTimeInterval(-40 * 86_400),
                expirationDate: now.addingTimeInterval(-5 * 86_400)),
            StoreTransaction(
                id: 22, productID: ShopItem.iconsAll.id,
                purchaseDate: now.addingTimeInterval(-300 * 86_400)),
        ]
        await store.refresh()
        #expect(store.proMonths == 2)
        await store.recordTenure()
        await store.recordTenure()
        let months = try await events(database).filter { $0.kind == .proMonth }.map(\.count)
        #expect(months.sorted() == [1, 2])
    }

    @Test func refundsCutProTimeAndNothingIsRecordedWithoutAProfile() async throws {
        let (store, client, database) = try await store(withUser: false)
        let now = Date.now
        client.past = [
            StoreTransaction(
                id: 30, productID: ShopItem.proYearly.id,
                purchaseDate: now.addingTimeInterval(-50 * 86_400),
                expirationDate: now.addingTimeInterval(300 * 86_400),
                revocationDate: now.addingTimeInterval(-15 * 86_400))
        ]
        await store.refresh()
        #expect(store.proMonths == 1)
        await store.recordTenure()
        #expect(try await events(database).isEmpty)
    }
}
