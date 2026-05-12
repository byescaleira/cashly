//
//  ApplicationActionTests.swift
//  CashlyKit
//
//  ApplicationAction is the umbrella enum dispatched from the
//  composition root. Verify each case wraps the expected per-feature
//  Action and that switch-by-case preserves discrimination.
//

import Testing
import CashlyDomain
@testable import CashlyPresentation

@Suite("ApplicationAction", .tags(.unit, .presentation, .local))
struct ApplicationActionTests {

    @Test("wraps every feature Action variant")
    func wrapsEveryVariant() {
        let cases: [ApplicationAction] = [
            .addCategory(.fetch),
            .addBudget(.fetch),
            .addTransaction(.fetch),
            .addUser(.fetch),
            .addTag(.fetch),
            .main(.fetch),
            .paywall(.fetch)
        ]

        for action in cases {
            switch action {
            case .addCategory(let inner): #expect(isFetch(inner))
            case .addBudget(let inner): #expect(isFetch(inner))
            case .addTransaction(let inner): #expect(isFetch(inner))
            case .addUser(let inner): #expect(isFetch(inner))
            case .addTag(let inner): #expect(isFetch(inner))
            case .main(let inner):
                if case .fetch = inner {} else { Issue.record("expected MainAction.fetch") }
            case .paywall(let inner):
                if case .fetch = inner {} else { Issue.record("expected PaywallAction.fetch") }
            }
        }
    }

    private func isFetch<A>(_ action: A) -> Bool {
        switch action {
        case let act as AddCategoryAction:
            if case .fetch = act { return true }
        case let act as AddBudgetAction:
            if case .fetch = act { return true }
        case let act as AddTransactionAction:
            if case .fetch = act { return true }
        case let act as AddUserAction:
            if case .fetch = act { return true }
        case let act as AddTagAction:
            if case .fetch = act { return true }
        default: return false
        }
        return false
    }
}
