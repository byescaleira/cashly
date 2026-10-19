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
    public var subscription: ProSubscription? {
        if let simulation { return simulation.subscription }
        return storeSubscription
    }
    public private(set) var hasLoaded = false
    public private(set) var hasRefreshed = false
    public private(set) var proMonths = 0
    public private(set) var introEligible: Set<ShopItem> = []
    public private(set) var isBuying = false
    public private(set) var pending: Set<ShopItem> = []
    public var selectedPlan = ShopItem.proYearly
    public var isConfirmingSwitch = false
    public var error: CashlyError?
    var simulation: StoreSimulation?
    private(set) var storeOwned: Set<ShopItem> = []
    private(set) var storeEntitlement = Entitlement.none
    private(set) var storeSubscription: ProSubscription?
    @ObservationIgnored private(set) var nextCheck: Date?
    @ObservationIgnored private var expiryCheck: Task<Void, Never>?
    static let expiryMargin = Duration.seconds(1)
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
        await withDiscardingTaskGroup { group in
            group.addTask { await self.listenToTransactions() }
            group.addTask { await self.listenToStatuses() }
        }
    }

    private func listenToTransactions() async {
        for await transaction in client.updates {
            guard !Task.isCancelled else { return }
            await handle(transaction)
        }
    }

    private func listenToStatuses() async {
        for await _ in client.statusUpdates {
            guard !Task.isCancelled else { return }
            await refresh()
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
        let now = Date.now
        let state = await StoreState.load(from: client, now: now)
        let wasTrial = if case .trial = storeEntitlement { true } else { false }
        storeOwned = state.owned
        storeEntitlement = state.entitlement
        storeSubscription = state.subscription
        hasRefreshed = true
        scheduleExpiryCheck(at: state.accessEnds, now: now)
        if wasTrial, !isTrialRenewing {
            await scheduler.replace(prefix: TrialReminder.id, with: [])
        }
        proMonths = await tenure()
    }

    private var isTrialRenewing: Bool {
        guard case .trial = storeEntitlement else { return false }
        return storeSubscription?.willRenew != false
    }

    private func scheduleExpiryCheck(at date: Date?, now: Date) {
        expiryCheck?.cancel()
        nextCheck = date.flatMap { $0 > now && $0 < .distantFuture ? $0 : nil }
        guard let nextCheck else { return }
        let delay = Duration.seconds(nextCheck.timeIntervalSince(now)) + Self.expiryMargin
        expiryCheck = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
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
        if let item = ShopItem(rawValue: transaction.productID) { pending.remove(item) }
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
        guard transaction.isFreeTrial, !transaction.isUpgraded,
            let ends = transaction.expirationDate,
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

    public var tenureKey: String {
        "\(session.user?.id ?? ""):\(proMonths)"
    }

    public func recordTenure() async {
        guard proMonths > 0, session.user != nil,
            let events = try? await session.repositories.game.events()
        else { return }
        let recorded = Set(events.filter { $0.kind == .proMonth }.map(\.count))
        let missing = (1...proMonths).filter { !recorded.contains($0) }.map {
            GameEvent(kind: .proMonth, value: "pro-month-\($0)", count: $0)
        }
        guard !missing.isEmpty else { return }
        try? await session.repositories.game.record(missing)
    }

    private func tenure(now: Date = .now) async -> Int {
        let plans = Set(ShopCatalog.plans.map(\.id))
        let periods = await client.history().compactMap { transaction -> DateInterval? in
            guard plans.contains(transaction.productID) else { return nil }
            let end = min(transaction.expiration, transaction.revocationDate ?? .distantFuture, now)
            return end > transaction.purchaseDate
                ? DateInterval(start: transaction.purchaseDate, end: end) : nil
        }
        return ProTenure.months(of: periods)
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
                    "Keep insights, intelligence and backups, or cancel in your Apple Account before the charge."
            ),
            components: CashlyCalendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: date))
    }
}
