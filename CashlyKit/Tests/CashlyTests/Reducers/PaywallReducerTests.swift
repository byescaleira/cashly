//
//  PaywallReducerTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
@testable import CashlyPresentation

@MainActor
@Suite("PaywallReducer", .tags(.unit, .presentation, .local))
struct PaywallReducerTests {
    let reducer = PaywallReducer()

    @Test("fetch flips loading + clears error")
    func fetchSetsLoading() {
        var state = PaywallState(isLoading: false, error: .unknown(message: "x"))
        _ = reducer.reduce(into: &state, action: .fetch)
        #expect(state.isLoading)
        #expect(state.error == nil)
    }

    @Test("update lands plans + clears loading + defaults selection to yearly")
    func updateSelectsYearly() {
        let plans = [
            SubscriptionPlan(id: "m", displayName: "Monthly", displayPrice: "$5", period: "monthly"),
            SubscriptionPlan(id: "y", displayName: "Yearly", displayPrice: "$40", period: "yearly")
        ]
        var state = PaywallState()
        _ = reducer.reduce(into: &state, action: .update(plans: plans))
        #expect(state.plans.count == 2)
        #expect(state.isLoading == false)
        #expect(state.selectedPlanId == "y")
    }

    @Test("update falls back to first plan when no yearly")
    func updateFallsBackToFirst() {
        let plans = [
            SubscriptionPlan(id: "m1", displayName: "Monthly", displayPrice: "$5", period: "monthly"),
            SubscriptionPlan(id: "m2", displayName: "Lifetime", displayPrice: "$99", period: nil)
        ]
        var state = PaywallState()
        _ = reducer.reduce(into: &state, action: .update(plans: plans))
        #expect(state.selectedPlanId == "m1")
    }

    @Test("update does not override pre-existing selection")
    func updatePreservesSelection() {
        let plans = [
            SubscriptionPlan(id: "m", displayName: "Monthly", displayPrice: "$5", period: "monthly"),
            SubscriptionPlan(id: "y", displayName: "Yearly", displayPrice: "$40", period: "yearly")
        ]
        var state = PaywallState(selectedPlanId: "m")
        _ = reducer.reduce(into: &state, action: .update(plans: plans))
        #expect(state.selectedPlanId == "m")
    }

    @Test("select updates selectedPlanId")
    func selectUpdatesId() {
        var state = PaywallState()
        _ = reducer.reduce(into: &state, action: .select(planId: "y"))
        #expect(state.selectedPlanId == "y")
    }

    @Test("purchase sets isPurchasing")
    func purchaseFlipsFlag() {
        var state = PaywallState()
        _ = reducer.reduce(into: &state, action: .purchase)
        #expect(state.isPurchasing)
    }

    @Test("purchaseSucceeded flips didPurchase + clears isPurchasing")
    func purchaseSucceeded() {
        var state = PaywallState(isPurchasing: true)
        _ = reducer.reduce(into: &state, action: .purchaseSucceeded)
        #expect(state.isPurchasing == false)
        #expect(state.didPurchase == true)
    }

    @Test("purchaseCancelled clears isPurchasing but not didPurchase")
    func purchaseCancelled() {
        var state = PaywallState(isPurchasing: true)
        _ = reducer.reduce(into: &state, action: .purchaseCancelled)
        #expect(state.isPurchasing == false)
        #expect(state.didPurchase == false)
    }

    @Test("error stores + clears loading + purchasing")
    func errorStores() {
        var state = PaywallState(isLoading: true, isPurchasing: true)
        _ = reducer.reduce(into: &state, action: .error(.unknown(message: "boom")))
        #expect(state.isLoading == false)
        #expect(state.isPurchasing == false)
        if case .unknown(let msg) = state.error {
            #expect(msg == "boom")
        } else {
            Issue.record("expected .unknown error")
        }
    }

    @Test("replace swaps the whole state")
    func replaceSwaps() {
        var state = PaywallState()
        let next = PaywallState(trigger: .intelligenceTab, isLoading: false, didPurchase: true)
        _ = reducer.reduce(into: &state, action: .replace(next))
        #expect(state.trigger == .intelligenceTab)
        #expect(state.didPurchase)
    }
}
