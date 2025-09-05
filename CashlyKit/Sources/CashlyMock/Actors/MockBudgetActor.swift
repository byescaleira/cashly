//
//  MockBudgetActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import RyzeFoundation
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
        budgets.filter { budget in
            (categories?.isEmpty == false ? categories!.contains(budget.category.id) : true) &&
            (date == nil ? true : budget.date.yearMonth == date?.timeIntervalSince1970.yearMonth)
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
        date: TimeInterval,
        summary: String
    ) async throws {
        let budget = Budget(
            id: id,
            amount: amount,
            category: category,
            date: date,
            summary: summary
        )
        budgets.append(budget)
    }
}
