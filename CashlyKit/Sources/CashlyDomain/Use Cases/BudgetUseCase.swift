//
//  BudgetUseCase.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

public protocol BudgetUseCase: Sendable {
    func getBudget(id: UUID) async throws -> Budget?
    func getBudgets() async throws -> [Budget]
    func removeBudget(id: UUID) async throws
    func removeBudgets() async throws
    func addBudget(
        id: UUID,
        amount: Double,
        category: Category,
        date: Date,
        summary: String
    ) async throws
}
