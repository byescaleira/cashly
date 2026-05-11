//
//  BudgetActorTests.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 30/08/25.
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock

@Suite("Budget Use Case", .tags(.unit, .data, .local))
actor BudgetActorTests {
    @MainActor
    let suite: CommonTestSuite = .init()
    
    @Test("Get budget by id")
    func testGetBudget() async throws {
        let categoryActual: CashlyDomain.Category = .mock
        let actual = Budget(
            id: UUID().uuidString,
            amount: 100,
            category: categoryActual,
            date: Date.now.timeIntervalSince1970.yearMonth,
            summary: "Budget"
        )
        
        try await suite.categoryUseCase.addCategory(
            id: categoryActual.id,
            user: "",
            name: categoryActual.name,
            color: categoryActual.color,
            icon: categoryActual.icon
        )
        
        let categoryExpected = try await suite.categoryUseCase.getCategory(id: categoryActual.id)
        
        suite.assertEqual(categoryActual, categoryExpected)
        
        try await suite.budgetUseCase.addBudget(
            id: actual.id,
            amount: actual.amount,
            category: actual.category,
            date: actual.date,
            summary: actual.summary
        )
        
        let expected = try await suite.budgetUseCase.getBudget(id: actual.id)
        
        suite.assertEqual(actual, expected)
    }
}
