//
//  CashlyCSVImporterTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain

@Suite("CashlyCSVImporter", .tags(.unit, .local))
struct CashlyCSVImporterTests {

    @Test("round-trips a single budget through exporter + importer")
    func budgetRoundTrip() throws {
        let user = User(id: "u", name: "U", photo: "")
        let category = CashlyDomain.Category(id: "c", user: user, name: "Food", color: "FF0000", icon: "fork")
        let budget = Budget(id: "b", amount: 99.5, category: category, date: 202_605, summary: "Groceries")
        let csv = CashlyCSVExporter.budgets([budget])
        let rows = try CashlyCSVImporter.budgets(csv)
        #expect(rows.count == 1)
        #expect(rows[0].amount == 99.5)
        #expect(rows[0].categoryName == "Food")
        #expect(rows[0].date == 202_605)
        #expect(rows[0].summary == "Groceries")
    }

    @Test("quoted fields with embedded commas survive the round-trip")
    func quotedFields() throws {
        let csv = """
        date,category,amount,summary
        202605,"Food, Snacks",12.34,"Lunch, with comma"
        """
        let rows = try CashlyCSVImporter.budgets(csv)
        #expect(rows[0].categoryName == "Food, Snacks")
        #expect(rows[0].summary == "Lunch, with comma")
    }

    @Test("missing header surfaces .missingHeader")
    func missingHeader() {
        let csv = "wrong,header,layout\n1,2,3"
        #expect(throws: CashlyCSVImporter.Failure.self) {
            try CashlyCSVImporter.budgets(csv)
        }
    }

    @Test("invalid amount surfaces line number")
    func invalidAmount() {
        let csv = """
        date,category,amount,summary
        202605,Food,not-a-number,Lunch
        """
        do {
            _ = try CashlyCSVImporter.budgets(csv)
            Issue.record("expected throw")
        } catch let CashlyCSVImporter.Failure.invalidAmount(line, _) {
            #expect(line == 2)
        } catch {
            Issue.record("wrong error: \(error)")
        }
    }

    @Test("transactions importer parses ISO date column")
    func transactionsHeader() throws {
        let csv = """
        date,summary,amount,category,budget,status,participants
        2026-05-13,Lunch,12.34,Food,Groceries,paid,Alice;Bob
        """
        let rows = try CashlyCSVImporter.transactions(csv)
        #expect(rows.count == 1)
        #expect(rows[0].participantNames == ["Alice", "Bob"])
        #expect(rows[0].amount == 12.34)
    }

    @Test("doubled quotes inside a quoted field decode to a single quote")
    func doubledQuotes() throws {
        let csv = "date,category,amount,summary\n202605,Food,9.99,\"She said \"\"hi\"\"\""
        let rows = try CashlyCSVImporter.budgets(csv)
        #expect(rows[0].summary == "She said \"hi\"")
    }
}
