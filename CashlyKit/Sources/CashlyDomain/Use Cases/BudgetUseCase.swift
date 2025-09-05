//
//  BudgetUseCase.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

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
        date: TimeInterval,
        summary: String
    ) async throws
}
