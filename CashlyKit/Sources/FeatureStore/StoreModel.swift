import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class StoreModel: EntitlementProviding, PurchaseProviding {
    public private(set) var products: [ShopItem: StoreProduct] = [:]
    public private(set) var owned: Set<ShopItem> = []
    public private(set) var entitlement = Entitlement.none
    public private(set) var hasLoaded = false
    public private(set) var hasRefreshed = false
    public var error: CashlyError?
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let client: any StoreClient

    public init(session: SessionModel, client: any StoreClient = StoreKitClient()) {
        self.session = session
        self.client = client
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
        self.owned = owned
        entitlement = if let plan { Entitlement(plan) } else { await lapsed() }
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

    public func restore() async throws {
        do {
            try await client.sync()
        } catch {
            throw CashlyError.persistence(error.localizedDescription)
        }
        await refresh()
    }

    func handle(_ transaction: StoreTransaction) async {
        if let credit = ShopItem(rawValue: transaction.productID)?.credit {
            guard await apply(credit, from: transaction) else { return }
        }
        await client.finish(transaction)
        await refresh()
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

    private func lapsed() async -> Entitlement {
        var latest: Date?
        for plan in ShopCatalog.plans {
            guard let transaction = await client.latest(for: plan.id) else { continue }
            latest = max(latest ?? .distantPast, transaction.expiration)
        }
        return latest.map(Entitlement.expired) ?? .none
    }
}

extension Entitlement {
    fileprivate init(_ transaction: StoreTransaction) {
        self =
            transaction.isFreeTrial
            ? .trial(expires: transaction.expiration) : .active(expires: transaction.expiration)
    }
}
