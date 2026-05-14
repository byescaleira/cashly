//
//  BudgetRolloverTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain

@Suite("Budget rollover", .tags(.unit, .local))
struct BudgetRolloverTests {

    private func user() -> User { User(id: "u", name: "U", photo: "") }

    private func category() -> CashlyDomain.Category {
        CashlyDomain.Category(id: "c", user: user(), name: "Food", color: "0", icon: "0")
    }

    @Test("rollsOver defaults to false")
    func defaultValue() {
        let b = Budget(id: "b", amount: 100, category: category(), date: 202_605, summary: "B")
        #expect(b.rollsOver == false)
    }

    @Test("previousYearMonth rolls back across January")
    func januaryRollback() {
        let jan = Budget(id: "1", amount: 0, category: category(), date: 202_601, summary: "")
        #expect(jan.previousYearMonth == 202_512)
    }

    @Test("previousYearMonth stays inside the year for mid-year months")
    func midYear() {
        let may = Budget(id: "1", amount: 0, category: category(), date: 202_605, summary: "")
        #expect(may.previousYearMonth == 202_604)
    }
}
