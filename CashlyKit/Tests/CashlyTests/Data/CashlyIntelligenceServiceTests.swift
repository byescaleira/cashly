//
//  CashlyIntelligenceServiceTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
@testable import CashlyData

@Suite("CashlyIntelligenceService data shaping", .tags(.unit, .data, .local))
struct CashlyIntelligenceServiceTests {

    private let user = User(id: "u", name: "A", photo: "https://x/a.png")

    private func budget(amount: Double = 100, categoryName: String = "Food", id: String = UUID().uuidString) -> Budget {
        Budget(
            id: id,
            amount: amount,
            category: CashlyDomain.Category(id: "c", user: user, name: categoryName, color: "#000", icon: "x"),
            date: 202604,
            summary: "s"
        )
    }

    private func transaction(
        budget: Budget,
        amount: Double,
        summary: String = "Tx",
        participants: [Participant] = [],
        splitValue: Double? = nil,
        paymentsPlan: Int? = nil,
        date: TimeInterval = 0
    ) -> CashlyDomain.Transaction {
        CashlyDomain.Transaction(
            id: UUID().uuidString,
            participants: participants,
            budget: budget,
            amount: amount,
            date: date,
            summary: summary,
            status: .settled,
            splitMode: nil,
            splitValue: splitValue,
            paymentsPlan: paymentsPlan
        )
    }

    // MARK: - tabularData

    @Test("tabularData(.budgetValue) groups transactions by budget and sums amount")
    func budgetValueGroupsByBudget() {
        let b1 = budget(categoryName: "Food", id: "b-food")
        let b2 = budget(categoryName: "Travel", id: "b-travel")
        let txs = [
            transaction(budget: b1, amount: 30),
            transaction(budget: b1, amount: 20),
            transaction(budget: b2, amount: 100)
        ]
        let rows = CashlyIntelligenceService.tabularData(
            model: .budgetValue,
            transactions: txs,
            tags: []
        )
        #expect(rows.count == 2)
        // find Food row
        let foodRow = rows.first { ($0["category"] as? String) == "Food" }
        #expect((foodRow?["target"] as? Double) == 50)
        let travelRow = rows.first { ($0["category"] as? String) == "Travel" }
        #expect((travelRow?["target"] as? Double) == 100)
    }

    @Test("budgetValue uses splitValue when participants present")
    func budgetValueRespectsParticipantSplit() {
        let b = budget(categoryName: "Split")
        let participant = Participant(
            id: "p", user: user, splitMode: .equal, splitValue: 0.5,
            status: .settled, transaction: ""
        )
        let tx = transaction(
            budget: b,
            amount: 100,
            participants: [participant],
            splitValue: 60
        )
        let rows = CashlyIntelligenceService.tabularData(
            model: .budgetValue,
            transactions: [tx],
            tags: []
        )
        #expect((rows.first?["target"] as? Double) == 60)
    }

    @Test("budgetValue divides by paymentsPlan when set and no participants")
    func budgetValueRespectsPaymentsPlan() {
        let b = budget(categoryName: "Installments")
        let tx = transaction(
            budget: b,
            amount: 300,
            paymentsPlan: 3
        )
        let rows = CashlyIntelligenceService.tabularData(
            model: .budgetValue,
            transactions: [tx],
            tags: []
        )
        #expect((rows.first?["target"] as? Double) == 100)
    }

    @Test("tabularData(.tagValue) groups by tag name match in summary")
    func tagValueGroupsByMatchingTag() {
        let b = budget()
        let coffeeTag = Tag(id: "t1", user: user, name: "Coffee", color: "#000", icon: "x")
        let travelTag = Tag(id: "t2", user: user, name: "Travel", color: "#000", icon: "y")
        let txs = [
            transaction(budget: b, amount: 5, summary: "Morning coffee"),
            transaction(budget: b, amount: 4, summary: "afternoon Coffee with friend"),
            transaction(budget: b, amount: 500, summary: "Travel — flight")
        ]
        let rows = CashlyIntelligenceService.tabularData(
            model: .tagValue,
            transactions: txs,
            tags: [coffeeTag, travelTag]
        )
        #expect(rows.count >= 2)
        let coffeeRow = rows.first { ($0["tag"] as? String) == "Coffee" }
        #expect((coffeeRow?["target"] as? Double) == 9)
        let travelRow = rows.first { ($0["tag"] as? String) == "Travel" }
        #expect((travelRow?["target"] as? Double) == 500)
    }

    @Test("tabularData(.categoryName) returns [] — wrong model")
    func tabularRejectsCategoryName() {
        let b = budget()
        let rows = CashlyIntelligenceService.tabularData(
            model: .categoryName,
            transactions: [transaction(budget: b, amount: 1)],
            tags: []
        )
        #expect(rows.isEmpty)
    }

    // MARK: - textData

    @Test("textData(.categoryName) emits one row per transaction with summary+category")
    func textDataEmitsPerTransaction() {
        let b1 = budget(categoryName: "Food", id: "b1")
        let b2 = budget(categoryName: "Travel", id: "b2")
        let txs = [
            transaction(budget: b1, amount: 1, summary: "lunch"),
            transaction(budget: b2, amount: 1, summary: "uber to airport")
        ]
        let rows = CashlyIntelligenceService.textData(
            model: .categoryName,
            transactions: txs
        )
        #expect(rows.count == 2)
        let lunch = rows.first { $0["text"] == "lunch" }
        #expect(lunch?["label"] == "Food")
        let uber = rows.first { $0["text"] == "uber to airport" }
        #expect(uber?["label"] == "Travel")
    }

    @Test("textData(.budgetValue) returns [] — wrong model")
    func textDataRejectsBudgetValue() {
        let b = budget()
        let rows = CashlyIntelligenceService.textData(
            model: .budgetValue,
            transactions: [transaction(budget: b, amount: 1)]
        )
        #expect(rows.isEmpty)
    }

    // MARK: - CashlyTabularData helpers

    @Test("CashlyTabularData.budgetValue packs date + category")
    func tabularBudgetValueHelper() {
        let row = CashlyTabularData.budgetValue(date: 202604, category: "Food")
        #expect((row["date"] as? Int) == 202604)
        #expect((row["category"] as? String) == "Food")
    }

    @Test("CashlyTabularData.tagValue packs date + tag")
    func tabularTagValueHelper() {
        let row = CashlyTabularData.tagValue(date: 202604, tag: "Coffee")
        #expect((row["date"] as? Int) == 202604)
        #expect((row["tag"] as? String) == "Coffee")
    }
}
