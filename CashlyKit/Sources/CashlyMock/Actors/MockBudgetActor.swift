//
import Foundation
//  MockBudgetActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import CashlyDomain
import SwiftData

actor MockBudgetActor: BudgetUseCase {
    var budgets = Budget.mocks

    init() {}

    func getBudget(id: String) async throws -> Budget? {
        budgets.first(where: { $0.id == id })
    }

    func getBudgets() async throws -> [Budget] {
        budgets
    }

    func getBudgets(
        categories: [String]?,
        date: Date?
    ) async throws -> [Budget] {
        let categoryIDs = categories ?? []
        return budgets.filter { budget in
            (categoryIDs.isEmpty || categoryIDs.contains(budget.category.id)) &&
            (date == nil ? true : budget.date == date?.timeIntervalSince1970.yearMonth)
        }
    }

    func removeBudget(id: String) async throws {
        guard let budget = try await getBudget(id: id),
              let index = budgets.firstIndex(of: budget)
        else { return }
        let _ = budgets.remove(at: index)
    }

    func removeBudgets() async throws {
        budgets = []
    }

    func addBudget(
        id: String,
        amount: Double,
        category: CashlyDomain.Category,
        date: Int,
        summary: String,
        rollsOver: Bool
    ) async throws {
        let budget = Budget(
            id: id,
            amount: amount,
            category: category,
            date: date,
            summary: summary,
            rollsOver: rollsOver
        )
        budgets.append(budget)
    }
}
