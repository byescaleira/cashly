//
//  TransactionInstallmentTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain

@Suite("Transaction installments", .tags(.unit, .local))
struct TransactionInstallmentTests {

    private func fixture(plan: Int?, yearMonth: Int) -> Transaction {
        let user = User(id: "u", name: "U", photo: "")
        let category = CashlyDomain.Category(id: "c", user: user, name: "F", color: "0", icon: "0")
        // Convert yearMonth back to a TimeInterval at month-start.
        let year = yearMonth / 100
        let month = yearMonth % 100
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        let date = Calendar(identifier: .gregorian).date(from: comps)!
        return Transaction(
            id: "t", participants: [], budget: nil,
            amount: 300, date: date.timeIntervalSince1970,
            summary: "S", status: .settled,
            splitMode: nil, splitValue: nil,
            paymentsPlan: plan, kind: .expense, needsReview: false,
            category: category
        )
    }

    @Test("no plan → single-month installment list")
    func noPlan() {
        let tx = fixture(plan: nil, yearMonth: 202_605)
        #expect(tx.installmentMonths() == [202_605])
        #expect(tx.installmentAmount == 300)
    }

    @Test("plan = 3 spreads across three consecutive months")
    func threeMonths() {
        let tx = fixture(plan: 3, yearMonth: 202_605)
        #expect(tx.installmentMonths() == [202_605, 202_606, 202_607])
        #expect(tx.installmentAmount == 100)
    }

    @Test("rolling past December bumps the year")
    func yearRollover() {
        let tx = fixture(plan: 4, yearMonth: 202_611)
        #expect(tx.installmentMonths() == [202_611, 202_612, 202_701, 202_702])
    }

    @Test("multi-year plan rolls year repeatedly")
    func multiYear() {
        let tx = fixture(plan: 14, yearMonth: 202_612)
        let months = tx.installmentMonths()
        #expect(months.first == 202_612)
        #expect(months.last == 202_801)
        #expect(months.count == 14)
    }

    @Test("touches matches every installment month and nothing else")
    func touches() {
        let tx = fixture(plan: 3, yearMonth: 202_605)
        #expect(tx.touches(yearMonth: 202_605))
        #expect(tx.touches(yearMonth: 202_607))
        #expect(!tx.touches(yearMonth: 202_608))
        #expect(!tx.touches(yearMonth: 202_604))
    }
}
