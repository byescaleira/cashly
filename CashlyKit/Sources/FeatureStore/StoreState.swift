import CashlyDomain
import Foundation

struct StoreState: Equatable, Sendable {
    var entitlement = Entitlement.none
    var subscription: ProSubscription?
    var owned: Set<ShopItem> = []

    static func load(from client: any StoreClient, now: Date) async -> StoreState {
        var state = StoreState()
        var plan: StoreTransaction?
        for transaction in await client.currentEntitlements() {
            guard transaction.revocationDate == nil, !transaction.isUpgraded,
                let item = ShopItem(rawValue: transaction.productID)
            else { continue }
            switch item.kind {
            case .nonConsumable: state.owned.insert(item)
            case .subscription:
                if transaction.expiration > (plan?.expiration ?? .distantPast) {
                    plan = transaction
                }
            case .consumable: break
            }
        }
        state.subscription = ProSubscription.current(
            await client.subscriptionStatuses(), at: now)
        state.entitlement =
            if let subscription = state.subscription {
                Entitlement(subscription, at: now)
            } else if let plan {
                Entitlement(plan)
            } else {
                await lapsed(in: client)
            }
        return state
    }

    var accessEnds: Date? {
        guard entitlement.isActive else { return nil }
        return subscription?.accessEnds ?? entitlement.expires
    }

    private static func lapsed(in client: any StoreClient) async -> Entitlement {
        var latest: Date?
        for plan in ShopCatalog.plans {
            guard let transaction = await client.latest(for: plan.id) else { continue }
            latest = max(latest ?? .distantPast, transaction.expiration)
        }
        return latest.map(Entitlement.expired) ?? .none
    }
}

@MainActor
public enum ProRule {
    public static func isPro(
        isEnforced: Bool, client: any StoreClient = StoreKitClient(),
        defaults: UserDefaults = .standard, now: Date = .now
    ) async -> Bool {
        guard isEnforced else { return true }
        if let simulated = StoreOverride.entitlement(in: defaults) { return simulated.isActive }
        return await StoreState.load(from: client, now: now).entitlement.isActive
    }
}

extension Entitlement {
    fileprivate init(_ transaction: StoreTransaction) {
        self =
            transaction.isFreeTrial
            ? .trial(expires: transaction.expiration) : .active(expires: transaction.expiration)
    }
}
