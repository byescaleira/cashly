//
//  TransactionExtensionsTests.swift
//  CashlyKit
//
//  Pure-function tests for Transaction.participantsAmount(filter:) and
//  Set<Transaction>.shareMessage(participants:).
//

import Foundation
import Testing
import CashlyDomain

@Suite("Transaction extensions", .tags(.unit, .data, .local))
struct TransactionExtensionsTests {

    private let user = User(id: "u", name: "Alice", photo: "p")
    private let userB = User(id: "u-b", name: "Bob", photo: "p")

    private func budget() -> Budget {
        Budget(
            id: "b",
            amount: 100,
            category: CashlyDomain.Category(id: "c", user: user, name: "Food", color: "#000", icon: "x"),
            date: 202604,
            summary: "B"
        )
    }

    private func transaction(
        participants: [Participant] = [],
        amount: Double = 100,
        splitValue: Double? = nil,
        paymentsPlan: Int? = nil
    ) -> Transaction {
        Transaction(
            id: UUID().uuidString,
            participants: participants,
            budget: budget(),
            amount: amount,
            date: 1_700_000_000,
            summary: "Tx",
            status: .settled,
            splitMode: nil,
            splitValue: splitValue,
            paymentsPlan: paymentsPlan
        )
    }

    // MARK: - participantsAmount with empty filter

    @Test("empty filter + no participants returns full amount")
    func emptyFilterNoParticipants() {
        let tx = transaction(amount: 100)
        #expect(tx.participantsAmount(filter: []) == 100)
    }

    @Test("empty filter + paymentsPlan divides amount by plan")
    func emptyFilterWithPaymentsPlan() {
        let tx = transaction(amount: 300, paymentsPlan: 3)
        #expect(tx.participantsAmount(filter: []) == 100)
    }

    @Test("empty filter + participants returns splitValue")
    func emptyFilterWithParticipants() {
        let p = Participant(id: "p", user: userB, splitMode: .equal, splitValue: 0,
                            status: .settled, transaction: "tx")
        let tx = transaction(participants: [p], amount: 100, splitValue: 30)
        #expect(tx.participantsAmount(filter: []) == 30)
    }

    // MARK: - participantsAmount with filter

    @Test("filter sums each participant's split contribution")
    func filterSumsContributions() {
        let pAlice = Participant(id: "p1", user: user, splitMode: .fixedAmount, splitValue: 20,
                                 status: .settled, transaction: "tx")
        let pBob = Participant(id: "p2", user: userB, splitMode: .fixedAmount, splitValue: 30,
                               status: .settled, transaction: "tx")
        let tx = transaction(participants: [pAlice, pBob], amount: 100)

        #expect(tx.participantsAmount(filter: [user]) == 20)
        #expect(tx.participantsAmount(filter: [userB]) == 30)
        #expect(tx.participantsAmount(filter: [user, userB]) == 50)
    }

    @Test("filter that matches no participants returns zero")
    func filterNoMatchReturnsZero() {
        let pAlice = Participant(id: "p1", user: user, splitMode: .fixedAmount, splitValue: 20,
                                 status: .settled, transaction: "tx")
        let tx = transaction(participants: [pAlice], amount: 100)
        let ghost = User(id: "ghost", name: "?", photo: "p")
        #expect(tx.participantsAmount(filter: [ghost]) == 0)
    }

    // MARK: - Set<Transaction>.shareMessage

    @Test("shareMessage contains expenses summary header + count line")
    func shareMessageStructure() {
        let pAlice = Participant(id: "p1", user: user, splitMode: .fixedAmount, splitValue: 20,
                                 status: .settled, transaction: "tx")
        let tx1 = transaction(participants: [pAlice], amount: 100)
        let tx2 = transaction(participants: [pAlice], amount: 50)
        let set: Set<Transaction> = [tx1, tx2]

        let message = set.shareMessage(participants: [user])
        #expect(message.contains("Expenses Summary"))
        #expect(message.contains("Transactions: 2"))
        #expect(message.contains("Total:"))
    }

    @Test("shareMessage with empty set still emits header + Total:")
    func shareMessageEmptySet() {
        let set: Set<Transaction> = []
        let message = set.shareMessage(participants: [user])
        #expect(message.contains("Expenses Summary"))
        #expect(message.contains("Transactions: 0"))
        #expect(message.contains("Total:"))
    }
}
