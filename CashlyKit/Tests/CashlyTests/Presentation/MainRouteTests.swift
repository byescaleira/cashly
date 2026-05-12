//
//  MainRouteTests.swift
//  CashlyKit
//
//  Validates MainRoute identity. Equality combines the case
//  discriminator AND the payload id (AddXState.id or Category.id) so
//  two `.addUser(state: A)` and `.addUser(state: B)` pushes resolve to
//  distinct NavigationStack entries — the previous discriminator-only
//  form corrupted the back stack when the same case was pushed twice
//  with different payloads.
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

    @Test(".addUser with same state id equates")
    func equalSameStateId() {
        let state = AddUserState.edit(id: "same-id")
        let a = MainRoute.addUser(state: state)
        let b = MainRoute.addUser(state: state)
        #expect(a == b)
    }

    @Test(".addUser with different state ids are NOT equal")
    func unequalDifferentStateIds() {
        let a = MainRoute.addUser(state: .new())
        let b = MainRoute.addUser(state: .edit(id: "different"))
        #expect(a != b)
    }

    @Test(".addUser and .addCategory are not equal regardless of payload")
    func differentCasesNotEqualEvenWithSameId() {
        let a = MainRoute.addUser(state: .edit(id: "x"))
        let b = MainRoute.addCategory(state: .edit(id: "x"))
        #expect(a != b)
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
