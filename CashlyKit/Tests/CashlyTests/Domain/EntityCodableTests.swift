//
//  EntityCodableTests.swift
//  CashlyKit
//
//  CashlyEntity refines PrismEntity (Codable + Equatable + Hashable +
//  Identifiable). Roundtrip through JSONEncoder/Decoder to verify the
//  conformance is actually wired and that decoded values are equal to
//  the originals.
//

import Foundation
import Testing
import CashlyDomain

@Suite("Domain entity Codable roundtrip", .tags(.unit, .data, .local))
struct EntityCodableTests {

    private func roundtrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    @Test("User roundtrips through JSON")
    func userRoundtrip() throws {
        let user = User(id: "u-1", name: "Alice", photo: "https://x/a.png")
        let decoded = try roundtrip(user)
        #expect(decoded == user)
    }

    @Test("Category roundtrips through JSON")
    func categoryRoundtrip() throws {
        let user = User(id: "u", name: "A", photo: "p")
        let category = CashlyDomain.Category(
            id: "c", user: user, name: "Food", color: "#FF0000", icon: "fork.knife"
        )
        let decoded = try roundtrip(category)
        #expect(decoded == category)
    }

    @Test("Budget roundtrips through JSON")
    func budgetRoundtrip() throws {
        let user = User(id: "u", name: "A", photo: "p")
        let category = CashlyDomain.Category(id: "c", user: user, name: "F", color: "#000", icon: "x")
        let budget = Budget(
            id: "b", amount: 123.45, category: category, date: 202604, summary: "B"
        )
        let decoded = try roundtrip(budget)
        #expect(decoded == budget)
    }

    @Test("Tag roundtrips through JSON")
    func tagRoundtrip() throws {
        let user = User(id: "u", name: "A", photo: "p")
        let tag = Tag(id: "t", user: user, name: "Coffee", color: "#8B4513", icon: "cup")
        let decoded = try roundtrip(tag)
        #expect(decoded == tag)
    }

    @Test("Participant roundtrips through JSON")
    func participantRoundtrip() throws {
        let user = User(id: "u", name: "A", photo: "p")
        let participant = Participant(
            id: "p", user: user, splitMode: .equal, splitValue: 0.5,
            status: .pendingToPay, transaction: "tx"
        )
        let decoded = try roundtrip(participant)
        #expect(decoded == participant)
    }

    @Test("Transaction roundtrips through JSON")
    func transactionRoundtrip() throws {
        let user = User(id: "u", name: "A", photo: "p")
        let category = CashlyDomain.Category(id: "c", user: user, name: "F", color: "#000", icon: "x")
        let budget = Budget(id: "b", amount: 100, category: category, date: 202604, summary: "B")
        let tx = CashlyDomain.Transaction(
            id: "tx", participants: [], budget: budget, amount: 42,
            date: 1_700_000_000, summary: "Dinner", status: .settled,
            splitMode: nil, splitValue: nil, paymentsPlan: nil
        )
        let decoded = try roundtrip(tx)
        #expect(decoded == tx)
    }

    @Test("TransactionStatus rawValue roundtrips")
    func statusRoundtrip() throws {
        for status in TransactionStatus.allCases {
            let decoded = try roundtrip(status)
            #expect(decoded == status)
        }
    }

    @Test("TransactionSplitMode rawValue roundtrips")
    func splitModeRoundtrip() throws {
        for mode in TransactionSplitMode.allCases {
            let decoded = try roundtrip(mode)
            #expect(decoded == mode)
        }
    }
}
