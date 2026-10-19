import CashlyData
import CashlyDomain
import FeatureCore
import FeatureStore
import Foundation
import StoreKit
import StoreKitTest
import Testing

@Suite(.serialized)
struct StoreKitTests {}

actor SilentScheduler: NotificationScheduling {
    func status() -> NotificationStatus { .denied }
    func requestAuthorization() -> Bool { false }
    func replace(prefix: String, with reminders: [Reminder]) {}
    func deliver(_ reminder: Reminder) {}
    func registerCaptureActions(_ groups: [CaptureActionGroup]) {}
    func setBadge(_ count: Int) {}
}

@MainActor
final class StoreKitFixture {
    static let owner = User(id: "store-owner", name: "Ana")

    let session: SKTestSession
    let database: CashlyDatabase
    let store: StoreModel

    init() async throws {
        session = try SKTestSession(configurationFileNamed: "Cashly")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(Self.owner)
        store = try await Self.model(on: database)
        await store.loadProducts()
        for _ in 0..<20 where store.introEligible != Set(ShopCatalog.plans) {
            try await Task.sleep(for: .milliseconds(250))
            await store.loadProducts()
        }
        await store.refresh()
    }

    static func model(on database: CashlyDatabase) async throws -> StoreModel {
        let user = SessionModel(provider: database, preference: .disabled)
        await user.refreshUsers()
        let defaults = try #require(UserDefaults(suiteName: "store-tests-\(UUID().uuidString)"))
        return StoreModel(
            session: user, client: StoreKitClient(), defaults: defaults,
            scheduler: SilentScheduler())
    }

    func subscribe(to plan: ShopItem) async -> Bool {
        store.selectedPlan = plan
        return await store.subscribe()
    }

    func transaction(for item: ShopItem) throws -> SKTestTransaction {
        try #require(session.allTransactions().last { $0.productIdentifier == item.id })
    }

    func events() async throws -> [GameEvent] {
        try await database.repositories(for: Self.owner.id).game.events()
    }

    func renewalState() async throws -> Product.SubscriptionInfo.RenewalState? {
        let plan = try await Product.products(for: [ShopItem.proMonthly.id]).first
        return try await plan?.subscription?.status.first?.state
    }

    func settle(until condition: () -> Bool) async throws {
        for _ in 0..<40 where !condition() {
            try await Task.sleep(for: .milliseconds(250))
            await store.refresh()
        }
    }

    func settle(_ state: Product.SubscriptionInfo.RenewalState) async throws {
        for _ in 0..<40 where try await renewalState() != state {
            try await Task.sleep(for: .milliseconds(250))
        }
        await store.refresh()
    }
}

extension Entitlement {
    var isTrial: Bool {
        if case .trial = self { true } else { false }
    }

    var isPaid: Bool {
        if case .active = self { true } else { false }
    }

    var isExpired: Bool {
        if case .expired = self { true } else { false }
    }
}
