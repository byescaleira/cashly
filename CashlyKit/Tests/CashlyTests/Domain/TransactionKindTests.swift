//
//  TransactionKindTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain

@Suite("TransactionKind + loan lifecycle", .tags(.unit, .local))
struct TransactionKindTests {

    private func fixture(kind: TransactionKind, status: TransactionStatus) -> Transaction {
        let user = User(id: "u", name: "U", photo: "")
        let category = CashlyDomain.Category(id: "c", user: user, name: "Food", color: "0", icon: "0")
        let budget = Budget(id: "b", amount: 100, category: category, date: 202_605, summary: "B")
        return Transaction(
            id: "t", participants: [], budget: budget,
            amount: 50, date: 0, summary: "S",
            status: status, splitMode: nil, splitValue: nil,
            paymentsPlan: nil, kind: kind, needsReview: false
        )
    }

    @Test("expense always contributes")
    func expense() {
        #expect(fixture(kind: .expense, status: .pendingToPay).contributesToExpenseTotals)
        #expect(fixture(kind: .expense, status: .settled).contributesToExpenseTotals)
    }

    @Test("income never contributes")
    func income() {
        #expect(!fixture(kind: .income, status: .pendingToPay).contributesToExpenseTotals)
        #expect(!fixture(kind: .income, status: .settled).contributesToExpenseTotals)
    }

    @Test("loan contributes only while pending")
    func loan() {
        #expect(fixture(kind: .loan, status: .pendingToPay).contributesToExpenseTotals)
        #expect(fixture(kind: .loan, status: .pendingToReceive).contributesToExpenseTotals)
        #expect(!fixture(kind: .loan, status: .settled).contributesToExpenseTotals)
        #expect(!fixture(kind: .loan, status: .canceled).contributesToExpenseTotals)
    }

    @Test("default kind is expense + needsReview false")
    func defaults() {
        let user = User(id: "u", name: "U", photo: "")
        let category = CashlyDomain.Category(id: "c", user: user, name: "F", color: "0", icon: "0")
        let budget = Budget(id: "b", amount: 0, category: category, date: 0, summary: "")
        let tx = Transaction(
            id: "t", participants: [], budget: budget,
            amount: 1, date: 0, summary: "",
            status: .settled, splitMode: nil, splitValue: nil, paymentsPlan: nil
        )
        #expect(tx.kind == .expense)
        #expect(tx.needsReview == false)
    }

    @Test("TransactionKind raw values are stable")
    func rawStability() {
        #expect(TransactionKind.expense.rawValue == 0)
        #expect(TransactionKind.income.rawValue == 1)
        #expect(TransactionKind.loan.rawValue == 2)
    }
}
