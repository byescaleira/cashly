import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class StoreModel: EntitlementProviding, PurchaseProviding {
    public private(set) var products: [ShopItem: StoreProduct] = [:]
    public var owned: Set<ShopItem> { simulation?.owned ?? storeOwned }
    public var isPending: Bool { pending.contains { $0.kind == .subscription } }
    public var entitlement: Entitlement { simulation?.entitlement ?? storeEntitlement }
    public private(set) var hasLoaded = false
    public private(set) var hasRefreshed = false
    public private(set) var introEligible: Set<ShopItem> = []
    public private(set) var isBuying = false
    public private(set) var pending: Set<ShopItem> = []
    public var selectedPlan = ShopItem.proYearly
    public var error: CashlyError?
    var simulation: StoreSimulation?
    private(set) var storeOwned: Set<ShopItem> = []
    private(set) var storeEntitlement = Entitlement.none
    @ObservationIgnored let defaults: UserDefaults
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let client: any StoreClient
    @ObservationIgnored private let scheduler: any NotificationScheduling

    public init(
        session: SessionModel, client: any StoreClient = StoreKitClient(),
        defaults: UserDefaults = .standard,
        scheduler: any NotificationScheduling = SystemNotifications()
    ) {
        self.session = session
        self.client = client
        self.defaults = defaults
        self.scheduler = scheduler
        simulation = .stored(in: defaults)
    }

    public func start() async {
        await loadProducts()
        await refresh()
        for transaction in await client.unfinished() { await handle(transaction) }
        for await transaction in client.updates {
            guard !Task.isCancelled else { return }
            await handle(transaction)
        }
    }

    public func loadProducts() async {
        do {
            let loaded = try await client.products(for: ShopItem.allCases.map(\.id))
            products = Dictionary(
                loaded.compactMap { product in ShopItem(rawValue: product.id).map { ($0, product) }
                },
                uniquingKeysWith: { first, _ in first })
            hasLoaded = !products.isEmpty
        } catch {
            self.error = .persistence(error.localizedDescription)
        }
        await refreshEligibility()
    }

    public func refresh() async {
        var owned: Set<ShopItem> = []
        var plan: StoreTransaction?
        for transaction in await client.currentEntitlements() {
            guard transaction.revocationDate == nil,
                let item = ShopItem(rawValue: transaction.productID)
            else { continue }
            switch item.kind {
            case .nonConsumable: owned.insert(item)
            case .subscription:
                if transaction.expiration > (plan?.expiration ?? .distantPast) {
                    plan = transaction
                }
            case .consumable: break
            }
        }
        storeOwned = owned
        storeEntitlement = if let plan { Entitlement(plan) } else { await lapsed() }
        hasRefreshed = true
    }

    public func price(for item: ShopItem) -> String? {
        products[item]?.displayPrice
    }

    public func purchase(_ item: ShopItem) async throws -> PurchaseResult {
        let result: StorePurchase
        do {
            result = try await client.purchase(item.id)
        } catch {
            throw CashlyError.persistence(error.localizedDescription)
        }
        switch result {
        case .success(let transaction):
            await handle(transaction)
            return .purchased
        case .pending: return .pending
        case .cancelled: return .cancelled
        }
    }

    public func subscribe() async -> Bool {
        await buy(selectedPlan)
    }

    public func buy(_ item: ShopItem) async -> Bool {
        isBuying = true
        defer { isBuying = false }
        do {
            switch try await purchase(item) {
            case .purchased:
                pending.remove(item)
                return true
            case .pending: pending.insert(item)
            case .cancelled: break
            }
        } catch {
            self.error = error as? CashlyError
        }
        return false
    }

    public func owns(_ item: ShopItem) -> Bool {
        ShopCatalog.owns(item, in: owned)
    }

    public func isPending(_ item: ShopItem) -> Bool {
        pending.contains(item)
    }

    public func restore() async throws {
        do {
            try await client.sync()
        } catch {
            throw CashlyError.persistence(error.localizedDescription)
        }
        await refresh()
        await refreshEligibility()
    }

    public func restoreSubscription() async -> Bool {
        await restoreQuietly()
        return entitlement.isActive
    }

    public func restoreItem(_ item: ShopItem) async -> Bool {
        await restoreQuietly()
        return owns(item)
    }

    public func restoreItems() async -> Bool {
        await restoreQuietly()
        return !owned.isEmpty
    }

    private func restoreQuietly() async {
        isBuying = true
        defer { isBuying = false }
        do {
            try await restore()
        } catch {
            self.error = error as? CashlyError
        }
    }

    func handle(_ transaction: StoreTransaction) async {
        if let credit = ShopItem(rawValue: transaction.productID)?.credit {
            guard await apply(credit, from: transaction) else { return }
        }
        await remindBeforeTrialEnds(transaction)
        await client.finish(transaction)
        await refresh()
    }

    private func refreshEligibility() async {
        var eligible: Set<ShopItem> = []
        for plan in ShopCatalog.plans {
            if await client.isEligibleForIntroOffer(plan.id) { eligible.insert(plan) }
        }
        introEligible = eligible
    }

    private func apply(_ credit: ShopCredit, from transaction: StoreTransaction) async -> Bool {
        guard session.user != nil else { return false }
        let event = GameEvent(
            kind: credit.eventKind, date: transaction.purchaseDate,
            value: String(transaction.id), count: credit.count * transaction.quantity)
        do {
            try await session.repositories.game.record([event])
            return true
        } catch {
            self.error = error as? CashlyError ?? .onSave
            return false
        }
    }

    private func remindBeforeTrialEnds(_ transaction: StoreTransaction) async {
        guard transaction.isFreeTrial, let ends = transaction.expirationDate,
            ShopItem(rawValue: transaction.productID)?.kind == .subscription
        else { return }
        let fires = ends.addingTimeInterval(-TrialReminder.lead)
        guard fires > .now else { return }
        if await scheduler.status() == .notDetermined {
            _ = await scheduler.requestAuthorization()
        }
        guard await scheduler.status() == .allowed else { return }
        await scheduler.replace(prefix: TrialReminder.id, with: [TrialReminder.reminder(at: fires)])
    }

    private func lapsed() async -> Entitlement {
        var latest: Date?
        for plan in ShopCatalog.plans {
            guard let transaction = await client.latest(for: plan.id) else { continue }
            latest = max(latest ?? .distantPast, transaction.expiration)
        }
        return latest.map(Entitlement.expired) ?? .none
    }
}

enum TrialReminder {
    static let id = "trial"
    static let lead: TimeInterval = 2 * 86_400

    static func reminder(at date: Date) -> Reminder {
        Reminder(
            id: id, title: String(appLocalized: "Your Cashly Pro trial ends in 2 days"),
            body: String(
                appLocalized:
                    "Keep recording without a pause, or cancel in your Apple Account before the charge."
            ),
            components: CashlyCalendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: date))
    }
}

extension Entitlement {
    fileprivate init(_ transaction: StoreTransaction) {
        self =
            transaction.isFreeTrial
            ? .trial(expires: transaction.expiration) : .active(expires: transaction.expiration)
    }
}
