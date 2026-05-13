//
//  CashlyCSVExporterTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain

@Suite("CashlyCSVExporter", .tags(.unit, .local))
struct CashlyCSVExporterTests {

    private func makeUser(id: String = "u") -> User {
        User(id: id, name: "Alice", photo: "p")
    }

    private func makeBudget(
        id: String = "b",
        amount: Double = 100,
        date: Int = 202604,
        summary: String = "Groceries"
    ) -> Budget {
        Budget(
            id: id,
            amount: amount,
            category: CashlyDomain.Category(
                id: "c", user: makeUser(), name: "Food",
                color: "#000", icon: "fork"
            ),
            date: date,
            summary: summary
        )
    }

    private func makeTx(
        id: String = "t",
        summary: String = "Lunch",
        amount: Double = 12.5,
        participants: [Participant] = []
    ) -> Transaction {
        Transaction(
            id: id,
            participants: participants,
            budget: makeBudget(),
            amount: amount,
            date: 1_715_000_000, // 2024-05-06
            summary: summary,
            status: .settled,
            splitMode: nil,
            splitValue: nil,
            paymentsPlan: nil
        )
    }

    @Test("transactions header is fixed")
    func transactionsHeader() {
        let csv = CashlyCSVExporter.transactions([])
        let firstLine = csv.split(separator: "\n").first.map(String.init)
        #expect(firstLine == "date,summary,amount,category,budget,status,participants")
    }

    @Test("amounts use dot-decimal regardless of locale")
    func amountsAreDotDecimal() {
        let csv = CashlyCSVExporter.transactions([makeTx(amount: 1234.5)])
        #expect(csv.contains(",1234.50,"))
    }

    @Test("ISO date column on transactions")
    func isoDate() {
        let csv = CashlyCSVExporter.transactions([makeTx()])
        // 1_715_000_000 epoch → 2024-05-06.
        #expect(csv.contains("2024-05-06"))
    }

    @Test("RFC 4180: commas in summary wrap field in quotes")
    func escapesComma() {
        let csv = CashlyCSVExporter.transactions([makeTx(summary: "Lunch, with friends")])
        #expect(csv.contains("\"Lunch, with friends\""))
    }

    @Test("RFC 4180: embedded quotes double up")
    func escapesQuote() {
        let csv = CashlyCSVExporter.transactions([makeTx(summary: "Café \"central\"")])
        #expect(csv.contains("\"Café \"\"central\"\"\""))
    }

    @Test("participants joined with semicolons")
    func joinsParticipants() {
        let userA = makeUser(id: "a")
        var userB = makeUser(id: "b"); userB.name = "Bob"
        let participants = [
            Participant(id: "p1", user: userA, splitMode: .equal, splitValue: 0, status: .settled, transaction: "t"),
            Participant(id: "p2", user: userB, splitMode: .equal, splitValue: 0, status: .settled, transaction: "t")
        ]
        let csv = CashlyCSVExporter.transactions([makeTx(participants: participants)])
        #expect(csv.contains("Alice;Bob") || csv.contains("Bob;Alice"))
    }

    @Test("budgets header is fixed")
    func budgetsHeader() {
        let csv = CashlyCSVExporter.budgets([])
        #expect(csv == "date,category,amount,summary")
    }

    @Test("budgets row contains all fields")
    func budgetsRow() {
        let csv = CashlyCSVExporter.budgets([makeBudget(amount: 500, summary: "Rent")])
        #expect(csv.contains("500.00"))
        #expect(csv.contains("Food"))
        #expect(csv.contains("Rent"))
        #expect(csv.contains("202604"))
    }
}
