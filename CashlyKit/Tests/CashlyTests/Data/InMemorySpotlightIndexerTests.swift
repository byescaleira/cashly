//
//  InMemorySpotlightIndexerTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyData

@Suite("InMemorySpotlightIndexer", .tags(.unit, .data, .local))
struct InMemorySpotlightIndexerTests {

    private func tx(_ id: String = "t") -> Transaction {
        let user = User(id: "u", name: "U", photo: "p")
        let category = CashlyDomain.Category(id: "c", user: user, name: "C", color: "#000", icon: "x")
        let budget = Budget(id: "b", amount: 100, category: category, date: 202604, summary: "s")
        return Transaction(
            id: id, participants: [], budget: budget, amount: 10,
            date: 0, summary: "x", status: .settled,
            splitMode: nil, splitValue: nil, paymentsPlan: nil
        )
    }

    @Test("index stores the transactions")
    func indexStores() async {
        let svc = InMemorySpotlightIndexer()
        await svc.index(transactions: [tx("a"), tx("b")])
        let stored = await svc.contents
        #expect(stored.count == 2)
    }

    @Test("re-indexing replaces the previous list")
    func indexReplaces() async {
        let svc = InMemorySpotlightIndexer()
        await svc.index(transactions: [tx("a")])
        await svc.index(transactions: [tx("b"), tx("c")])
        let stored = await svc.contents
        #expect(stored.count == 2)
        #expect(stored.contains(where: { $0.id == "b" }))
    }

    @Test("clear empties the index")
    func clearEmpties() async {
        let svc = InMemorySpotlightIndexer()
        await svc.index(transactions: [tx("a")])
        await svc.clear()
        let stored = await svc.contents
        #expect(stored.isEmpty)
    }
}
