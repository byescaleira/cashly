//
//  BudgetUseCase.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import Foundation

public protocol BudgetUseCase: Sendable {
    func getBudget(id: String) async throws -> Budget?
    func getBudgets() async throws -> [Budget]
    func getBudgets(
        categories: [String]?,
        date: Date?
    ) async throws -> [Budget]
    func removeBudget(id: String) async throws
    func removeBudgets() async throws
    func addBudget(
        id: String,
        amount: Double,
        category: Category,
        date: Int,
        summary: String,
        rollsOver: Bool
    ) async throws
}

public extension BudgetUseCase {
    /// K9 back-compat: pre-K9 callsites don't pass rollsOver.
    func addBudget(
        id: String,
        amount: Double,
        category: Category,
        date: Int,
        summary: String
    ) async throws {
        try await addBudget(
            id: id,
            amount: amount,
            category: category,
            date: date,
            summary: summary,
            rollsOver: false
        )
    }
}
