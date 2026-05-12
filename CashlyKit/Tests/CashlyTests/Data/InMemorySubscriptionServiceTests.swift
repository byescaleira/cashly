//
//  InMemorySubscriptionServiceTests.swift
//  CashlyKit
//
//  Behavioural coverage for the mock-side SubscriptionUseCase used by
//  tests and previews. Verifies the contract that B2's feature gating
//  will lean on: default tier, purchase happy path, controllable
//  failure, restore is a no-op, status stream emits on tier flips.
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock

@Suite("InMemory Subscription Service", .tags(.unit, .data, .local))
struct InMemorySubscriptionServiceTests {

    @Test("default tier is .free")
    func defaultsToFree() async {
        let service = InMemorySubscriptionService()
        let status = await service.currentStatus()
        #expect(status.tier == .free)
        #expect(status.activePlanId == nil)
    }

    @Test("availablePlans returns the seeded plans")
    func availablePlans() async {
        let service = InMemorySubscriptionService()
        let plans = await service.availablePlans()
        #expect(plans.count == InMemorySubscriptionService.defaultPlans.count)
        #expect(plans.contains(where: { $0.id == "com.cashly.pro.monthly" }))
    }

    @Test("purchase happy path flips tier to .pro")
    func purchaseHappyPath() async {
        let service = InMemorySubscriptionService()
        let outcome = await service.purchase(planId: "com.cashly.pro.monthly")
        #expect(outcome == .success)
        let status = await service.currentStatus()
        #expect(status.tier == .pro)
        #expect(status.activePlanId == "com.cashly.pro.monthly")
        #expect(status.willAutoRenew == true)
    }

    @Test("purchase of unknown plan id fails without changing tier")
    func purchaseUnknownPlan() async {
        let service = InMemorySubscriptionService()
        let outcome = await service.purchase(planId: "com.cashly.bogus")
        if case .failed = outcome {} else { Issue.record("expected .failed") }
        let status = await service.currentStatus()
        #expect(status.tier == .free)
    }

    @Test("nextPurchaseOutcome override surfaces .userCancelled")
    func purchaseUserCancelled() async {
        let service = InMemorySubscriptionService(nextPurchaseOutcome: .userCancelled)
        let outcome = await service.purchase(planId: "com.cashly.pro.monthly")
        #expect(outcome == .userCancelled)
        let status = await service.currentStatus()
        #expect(status.tier == .free)
    }

    @Test("setTier test seam flips tier without going through purchase")
    func setTierFlip() async {
        let service = InMemorySubscriptionService()
        await service.setTier(.pro)
        var status = await service.currentStatus()
        #expect(status.tier == .pro)
        await service.setTier(.free)
        status = await service.currentStatus()
        #expect(status.tier == .free)
    }

    @Test("simulateRevocation drops Pro to Free")
    func revocationDropsTier() async {
        let service = InMemorySubscriptionService()
        await service.setTier(.pro)
        await service.simulateRevocation()
        let status = await service.currentStatus()
        #expect(status.tier == .free)
        #expect(status.activePlanId == nil)
    }

    @Test("simulateExpiry drops Pro to Free")
    func expiryDropsTier() async {
        let service = InMemorySubscriptionService()
        await service.setTier(.pro)
        await service.simulateExpiry()
        let status = await service.currentStatus()
        #expect(status.tier == .free)
    }

    @Test("statusUpdates stream emits initial value and every change")
    func statusStreamEmits() async {
        let service = InMemorySubscriptionService()
        let stream = service.statusUpdates()
        var iterator = stream.makeAsyncIterator()
        // Initial yield = current status.
        let initial = await iterator.next()
        #expect(initial?.tier == .free)
        await service.setTier(.pro)
        let upgraded = await iterator.next()
        #expect(upgraded?.tier == .pro)
        await service.simulateRevocation()
        let revoked = await iterator.next()
        #expect(revoked?.tier == .free)
    }
}
