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
        summary: String
    ) async throws
}
