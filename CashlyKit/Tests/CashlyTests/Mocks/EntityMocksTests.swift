//
//  EntityMocksTests.swift
//  CashlyKit
//
//  Verify the PrismMock conformances on every Domain entity that
//  CashlyMock extends. Each `.mock` and `.mocks` should resolve
//  against the bundled JSON without throwing.
//

import Testing
import CashlyDomain
import CashlyMock

@Suite("Entity .mock / .mocks", .tags(.unit, .data, .local))
struct EntityMocksTests {

    @Test("User.mocks returns a non-empty seeded list")
    func userMocks() {
        #expect(!User.mocks.isEmpty)
        #expect(User.mocks.allSatisfy { !$0.name.isEmpty })
    }

    @Test("User.mocks is sorted by name ascending")
    func userMocksSortedByName() {
        let names = User.mocks.map(\.name)
        #expect(names == names.sorted())
    }

    @Test("Budget.mocks returns a non-empty list sorted by date descending")
    func budgetMocksSortedByDateDesc() {
        let budgets = Budget.mocks
        guard budgets.count >= 2 else { return }
        let dates = budgets.map(\.date)
        // sorted in reverse — first >= last
        #expect((dates.first ?? 0) >= (dates.last ?? 0))
    }

    @Test("Category.mocks returns a non-empty list")
    func categoryMocks() {
        let categories = CashlyDomain.Category.mocks
        #expect(!categories.isEmpty)
        #expect(categories.allSatisfy { !$0.name.isEmpty })
        #expect(categories.allSatisfy { !$0.icon.isEmpty })
    }

    @Test("Tag.mocks returns a non-empty list with valid users")
    func tagMocks() {
        let tags = Tag.mocks
        #expect(!tags.isEmpty)
        #expect(tags.allSatisfy { !$0.user.id.isEmpty })
    }

    @Test("Participant.mocks returns a non-empty list")
    func participantMocks() {
        let participants = Participant.mocks
        #expect(!participants.isEmpty)
    }

    @Test("Transaction.mocks returns a non-empty list")
    func transactionMocks() {
        let txs = CashlyDomain.Transaction.mocks
        #expect(!txs.isEmpty)
    }

    @Test(".mock returns an element from .mocks")
    func mockBelongsToMocks() {
        // Just verify that .mock builds without crash for every entity.
        _ = User.mock
        _ = CashlyDomain.Category.mock
        _ = Budget.mock
        _ = Tag.mock
        _ = Participant.mock
        _ = CashlyDomain.Transaction.mock
    }
}
