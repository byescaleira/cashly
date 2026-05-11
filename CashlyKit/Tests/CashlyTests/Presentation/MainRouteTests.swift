//
//  MainRouteTests.swift
//  CashlyKit
//
//  Validates the discriminator-based equality + hashing on MainRoute,
//  which is intentional: navigation routes must equate by case
//  identity, not by the variant payload (different state values for
//  the same destination should still be considered the same route).
//

import Testing
import CashlyDomain
@testable import CashlyPresentation

@MainActor
@Suite("MainRoute", .tags(.unit, .presentation, .local))
struct MainRouteTests {

    @Test("two .home routes are equal")
    func equalCasesNoPayload() {
        #expect(MainRoute.home == .home)
        #expect(MainRoute.transaction == .transaction)
    }

    @Test(".addUser with different states still equates by case")
    func equalCasesIgnorePayload() {
        let a = MainRoute.addUser(state: .new())
        let b = MainRoute.addUser(state: .edit(id: "different"))
        #expect(a == b)
    }

    @Test("different cases are not equal")
    func differentCasesNotEqual() {
        #expect(MainRoute.home != .transaction)
        #expect(MainRoute.home != .category)
        #expect(MainRoute.home != .intelligence)
    }

    @Test("equal routes hash equally")
    func equalRoutesHashEqually() {
        let a = MainRoute.home
        let b = MainRoute.home
        var h1 = Hasher(); var h2 = Hasher()
        a.hash(into: &h1)
        b.hash(into: &h2)
        #expect(h1.finalize() == h2.finalize())
    }

    @Test("different cases hash differently")
    func differentCasesHashDifferently() {
        let a = MainRoute.home
        let b = MainRoute.intelligence
        var h1 = Hasher(); var h2 = Hasher()
        a.hash(into: &h1)
        b.hash(into: &h2)
        #expect(h1.finalize() != h2.finalize())
    }

    @Test("every case has push as default navigationStyle")
    func allPush() {
        let routes: [MainRoute] = [
            .addUser(state: .new()),
            .addCategory(state: .new()),
            .addBudget(state: .new()),
            .addTransaction(state: .new()),
            .addTag(state: .new()),
            .category,
            .transaction,
            .home,
            .intelligence
        ]
        for r in routes {
            if case .push = r.navigationStyle {} else {
                Issue.record("expected .push for \(r)")
            }
        }
    }
}
