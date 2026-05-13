//
//  MockAdapterActorTests.swift
//  CashlyKit
//
//  Verify the FK-resolution behavior of the mock adapter. It uses
//  CashlyResource mock JSON for users/categories/budgets/participants,
//  so the tests assert against fixture ids that exist in those files.
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock

@Suite("MockAdapterActor", .tags(.unit, .data, .local))
struct MockAdapterActorTests {
    @MainActor private func adapter() -> AdapterUseCase {
        MockCashlyFactory().makeAdapter()
    }

    @Test("userAdapted always builds a User (no FK)")
    func userAdaptedAlwaysSucceeds() async throws {
        let adapter = await adapter()
        let user = try await adapter.userAdapted(
            id: "anything",
            name: "Test",
            photo: "https://x/p.png"
        )
        #expect(user.id == "anything")
        #expect(user.name == "Test")
        #expect(user.photo == "https://x/p.png")
    }

    @Test("categoryAdapted returns nil when user id not in fixtures")
    func categoryAdaptedFKMiss() async throws {
        let adapter = await adapter()
        let category = try await adapter.categoryAdapted(
            id: "c1",
            user: "ghost-user-id",
            name: "Food",
            color: "#000",
            icon: "fork.knife"
        )
        #expect(category == nil)
    }

    @Test("categoryAdapted resolves when user matches a fixture user")
    func categoryAdaptedFKHit() async throws {
        let adapter = await adapter()
        let referenceUser = User.mocks.first!
        let category = try await adapter.categoryAdapted(
            id: "c1",
            user: referenceUser.id,
            name: "Food",
            color: "#FF0000",
            icon: "fork.knife"
        )
        #expect(category?.id == "c1")
        #expect(category?.name == "Food".capitalized)
        #expect(category?.user.id == referenceUser.id)
    }

    @Test("tagAdapted returns nil when user FK missing")
    func tagAdaptedFKMiss() async throws {
        let adapter = await adapter()
        let tag = try await adapter.tagAdapted(
            id: "t1",
            user: "ghost-user",
            name: "Coffee",
            color: "#000",
            icon: "x"
        )
        #expect(tag == nil)
    }

    @Test("tagAdapted resolves with fixture user")
    func tagAdaptedFKHit() async throws {
        let adapter = await adapter()
        let user = User.mocks.first!
        let tag = try await adapter.tagAdapted(
            id: "t1",
            user: user.id,
            name: "Coffee",
            color: "#000",
            icon: "x"
        )
        #expect(tag?.id == "t1")
        #expect(tag?.user.id == user.id)
    }

    @Test("transactionAdapted returns nil when budget FK missing")
    func transactionAdaptedFKMiss() async throws {
        let adapter = await adapter()
        let tx = try await adapter.transactionAdapted(
            id: "tx1",
            participants: [],
            budget: "ghost-budget",
            amount: 1,
            date: 0,
            summary: "x",
            status: TransactionStatus.settled.rawValue,
            splitMode: nil,
            splitValue: nil,
            paymentsPlan: nil,
            kind: TransactionKind.expense.rawValue,
            needsReview: false
        )
        #expect(tx == nil)
    }

    @Test("transactionAdapted returns nil when status raw is invalid")
    func transactionAdaptedInvalidStatus() async throws {
        let adapter = await adapter()
        let budget = Budget.mocks.first!
        let tx = try await adapter.transactionAdapted(
            id: "tx1",
            participants: [],
            budget: budget.id,
            amount: 1,
            date: 0,
            summary: "x",
            status: 999, // not a valid TransactionStatus raw
            splitMode: nil,
            splitValue: nil,
            paymentsPlan: nil,
            kind: TransactionKind.expense.rawValue,
            needsReview: false
        )
        #expect(tx == nil)
    }
}
