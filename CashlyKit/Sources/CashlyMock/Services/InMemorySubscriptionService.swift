//
//  InMemorySubscriptionService.swift
//  CashlyKit
//
//  Test/preview SubscriptionUseCase. Configurable initial tier and a
//  hook for toggling tier at runtime so paywall flows can be driven
//  by tests without StoreKit.
//

import Foundation
import CashlyDomain

public actor InMemorySubscriptionService: SubscriptionUseCase {
    private var status: SubscriptionStatus
    private var plans: [SubscriptionPlan]
    private var continuations: [UUID: AsyncStream<SubscriptionStatus>.Continuation] = [:]
    /// Override the next `purchase(planId:)` outcome. Defaults to
    /// `.success` so the happy path doesn't need configuration.
    public var nextPurchaseOutcome: PurchaseOutcome

    public init(
        initial: SubscriptionStatus = .free,
        plans: [SubscriptionPlan] = InMemorySubscriptionService.defaultPlans,
        nextPurchaseOutcome: PurchaseOutcome = .success
    ) {
        self.status = initial
        self.plans = plans
        self.nextPurchaseOutcome = nextPurchaseOutcome
    }

    public static let defaultPlans: [SubscriptionPlan] = [
        SubscriptionPlan(
            id: "com.cashly.pro.monthly",
            displayName: "Pro Monthly",
            displayPrice: "$4.99",
            period: "monthly"
        ),
        SubscriptionPlan(
            id: "com.cashly.pro.yearly",
            displayName: "Pro Yearly",
            displayPrice: "$39.99",
            period: "yearly"
        )
    ]

    public func availablePlans() async -> [SubscriptionPlan] { plans }
    public func refreshPlans() async { /* no-op */ }
    public func currentStatus() async -> SubscriptionStatus { status }

    public func purchase(planId: String) async -> PurchaseOutcome {
        guard plans.contains(where: { $0.id == planId }) else {
            return .failed(reason: "Plan unavailable.")
        }
        let outcome = nextPurchaseOutcome
        if outcome == .success {
            updateStatus(SubscriptionStatus(
                tier: .pro,
                activePlanId: planId,
                expiresAt: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
                willAutoRenew: true
            ))
        }
        return outcome
    }

    public func restore() async {
        // Mirrors production restore: no-op when nothing's been
        // purchased in this session.
    }

    public nonisolated func statusUpdates() -> AsyncStream<SubscriptionStatus> {
        AsyncStream { continuation in
            let id = UUID()
            Task { [weak self] in
                guard let self else { continuation.finish(); return }
                await self.register(continuation: continuation, id: id)
            }
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in await self?.unregister(id: id) }
            }
        }
    }

    /// Test seam — flip the tier from `.free` to `.pro` (or back)
    /// without going through `purchase`.
    public func setTier(_ tier: SubscriptionTier) {
        let next: SubscriptionStatus = tier == .pro
            ? SubscriptionStatus(
                tier: .pro,
                activePlanId: plans.first?.id,
                expiresAt: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
                willAutoRenew: true
            )
            : .free
        updateStatus(next)
    }

    private func register(
        continuation: AsyncStream<SubscriptionStatus>.Continuation,
        id: UUID
    ) {
        continuations[id] = continuation
        continuation.yield(status)
    }

    private func unregister(id: UUID) {
        continuations[id] = nil
    }

    private func updateStatus(_ new: SubscriptionStatus) {
        guard status != new else { return }
        status = new
        for continuation in continuations.values {
            continuation.yield(new)
        }
    }
}
