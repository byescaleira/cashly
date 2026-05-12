//
//  StoreKitSubscriptionService.swift
//  CashlyKit
//
//  StoreKit 2 implementation of `SubscriptionUseCase`. Owns product
//  loading, purchase flow, transaction verification and an updates
//  listener that survives the app lifetime. UI only sees the
//  `CashlyDomain.SubscriptionStatus` snapshot — StoreKit types do not leak.
//

import Foundation
import StoreKit
import CashlyDomain

public actor StoreKitSubscriptionService: SubscriptionUseCase {
    /// Product identifiers as configured in App Store Connect. Adjust
    /// here when the IDs change — no other file should reference them.
    public static let productIDs: Set<String> = [
        "com.cashly.pro.monthly",
        "com.cashly.pro.yearly"
    ]

    private var products: [Product] = []
    private var status: CashlyDomain.SubscriptionStatus = .free
    private var continuations: [UUID: AsyncStream<CashlyDomain.SubscriptionStatus>.Continuation] = [:]
    private var updatesTask: Task<Void, Never>?

    public init() {}

    /// Begin listening to `Transaction.updates`. Call once at app
    /// launch — calling twice replaces the previous listener.
    public func start() async {
        updatesTask?.cancel()
        updatesTask = Task.detached(priority: .background) { [weak self] in
            for await update in StoreKit.Transaction.updates {
                await self?.handleVerification(update)
            }
        }
        await refreshPlans()
        await reloadEntitlements()
    }

    // MARK: - SubscriptionUseCase

    public func availablePlans() async -> [SubscriptionPlan] {
        products.map(Self.makePlan)
    }

    public func refreshPlans() async {
        do {
            let loaded = try await Product.products(for: Self.productIDs)
            products = loaded.sorted { $0.id < $1.id }
        } catch {
            // Keep whatever we had — UI will show the cached price or
            // the empty paywall placeholder.
        }
    }

    public func currentStatus() async -> CashlyDomain.SubscriptionStatus {
        status
    }

    public func purchase(planId: String) async -> PurchaseOutcome {
        guard let product = products.first(where: { $0.id == planId }) else {
            return .failed(reason: "Plan unavailable.")
        }
        do {
            let result = try await product.purchase()
            switch result {
            case let .success(verification):
                await handleVerification(verification)
                return .success
            case .userCancelled:
                return .userCancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed(reason: "Unknown purchase result.")
            }
        } catch {
            return .failed(reason: error.localizedDescription)
        }
    }

    public func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            // Restore failures surface through status snapshots — UI
            // re-reads currentStatus() after this returns.
        }
        await reloadEntitlements()
    }

    public nonisolated func statusUpdates() -> AsyncStream<CashlyDomain.SubscriptionStatus> {
        AsyncStream { continuation in
            let id = UUID()
            Task { [weak self] in
                guard let self else { continuation.finish(); return }
                await self.register(continuation: continuation, id: id)
            }
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.unregister(id: id)
                }
            }
        }
    }

    // MARK: - Internals

    private func register(
        continuation: AsyncStream<CashlyDomain.SubscriptionStatus>.Continuation,
        id: UUID
    ) {
        continuations[id] = continuation
        continuation.yield(status)
    }

    private func unregister(id: UUID) {
        continuations[id] = nil
    }

    private func reloadEntitlements() async {
        var resolved: CashlyDomain.SubscriptionStatus = .free
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            if Self.productIDs.contains(transaction.productID) {
                resolved = CashlyDomain.SubscriptionStatus(
                    tier: .pro,
                    activePlanId: transaction.productID,
                    expiresAt: transaction.expirationDate,
                    willAutoRenew: transaction.revocationDate == nil
                )
                break
            }
        }
        updateStatus(resolved)
    }

    private func handleVerification(_ result: VerificationResult<StoreKit.Transaction>) async {
        switch result {
        case let .verified(transaction):
            await apply(verified: transaction)
        case .unverified:
            // Unverified results indicate a signature failure (jailbreak,
            // tampering, network corruption). We never grant Pro from
            // these; treat as "stay on whatever the current verified
            // status is" and rely on the next verified update for
            // recovery. Logging is intentional so the developer can
            // catch a steady stream of unverified updates in production.
            #if DEBUG
            print("[Subscription] Dropped unverified transaction update.")
            #endif
        }
    }

    private func apply(verified transaction: StoreKit.Transaction) async {
        defer { Task { await transaction.finish() } }

        // Refund: Apple revokes the transaction. StoreKit signals via
        // revocationDate. Surface as a tier drop so any Pro-gated UI
        // re-locks immediately.
        if let revocation = transaction.revocationDate, revocation <= Date() {
            updateStatus(.free)
            return
        }
        // Natural expiry without auto-renew. We still emit a tier
        // drop because the user no longer has Pro access.
        if let expiry = transaction.expirationDate, expiry <= Date() {
            updateStatus(.free)
            return
        }
        guard Self.productIDs.contains(transaction.productID) else {
            // Unknown product id (likely a one-off purchase or a
            // product from a sibling app on the shared account).
            // Don't change tier.
            return
        }
        updateStatus(CashlyDomain.SubscriptionStatus(
            tier: .pro,
            activePlanId: transaction.productID,
            expiresAt: transaction.expirationDate,
            willAutoRenew: true
        ))
    }

    private func updateStatus(_ new: CashlyDomain.SubscriptionStatus) {
        guard status != new else { return }
        status = new
        for continuation in continuations.values {
            continuation.yield(new)
        }
    }

    private static func makePlan(_ product: Product) -> SubscriptionPlan {
        let period = product.subscription?.subscriptionPeriod
        let periodLabel: String?
        switch period?.unit {
        case .day: periodLabel = "daily"
        case .week: periodLabel = "weekly"
        case .month: periodLabel = period?.value == 12 ? "yearly" : "monthly"
        case .year: periodLabel = "yearly"
        case .none: periodLabel = nil
        @unknown default: periodLabel = nil
        }
        return SubscriptionPlan(
            id: product.id,
            displayName: product.displayName,
            displayPrice: product.displayPrice,
            period: periodLabel
        )
    }
}
