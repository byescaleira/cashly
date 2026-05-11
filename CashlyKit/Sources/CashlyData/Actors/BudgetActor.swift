//
//  BudgetActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import Foundation
import CashlyDomain
import SwiftData

@ModelActor
public actor BudgetActor: BudgetUseCase {
    lazy var adapter: AdapterUseCase = AdapterActor(modelContainer: modelContainer)

    public func getBudget(id: String) async throws -> Budget? {
        let predicate: Predicate<BudgetEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<BudgetEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return nil }
        return try await adapter.budgetAdapted(
            id: entity.id,
            amount: entity.amount,
            category: entity.category,
            date: entity.date,
            summary: entity.summary
        )
    }

    public func getBudgets() async throws -> [Budget] {
        let descriptor = FetchDescriptor<BudgetEntity>(sortBy: [.init(\.date, order: .reverse)])
        let entities = try modelContext.fetch(descriptor)
        var budgets = [Budget]()
        for entity in entities {
            if let budget = try await adapter.budgetAdapted(
                id: entity.id,
                amount: entity.amount,
                category: entity.category,
                date: entity.date,
                summary: entity.summary
            ) {
                budgets.append(budget)
            }
        }
        return budgets
    }

    public func getBudgets(
        categories: [String]?,
        date: Date?
    ) async throws -> [Budget] {
        let predicateCategory: Predicate<String>
        if let categories {
            predicateCategory = #Predicate { categories.contains($0) }
        } else {
            predicateCategory = #Predicate { _ in true }
        }

        let predicateDate: Predicate<Int>
        if let date {
            let yearMonth = date.timeIntervalSince1970.yearMonth
            predicateDate = #Predicate { $0 == yearMonth }
        } else {
            predicateDate = #Predicate { _ in true }
        }

        let predicate: Predicate<BudgetEntity> = #Predicate {
            predicateCategory.evaluate($0.category) &&
            predicateDate.evaluate($0.date)
        }

        let descriptor = FetchDescriptor<BudgetEntity>(
            predicate: predicate,
            sortBy: [.init(\.date, order: .reverse)]
        )

        let entities = try modelContext.fetch(descriptor)
        var budgets = [Budget]()
        for entity in entities {
            if let budget = try await adapter.budgetAdapted(
                id: entity.id,
                amount: entity.amount,
                category: entity.category,
                date: entity.date,
                summary: entity.summary
            ) {
                budgets.append(budget)
            }
        }
        return budgets
    }

    public func removeBudget(id: String) async throws {
        let predicate: Predicate<BudgetEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<BudgetEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(entity)
        try modelContext.save()
    }

    public func removeBudgets() async throws {
        let descriptor = FetchDescriptor<BudgetEntity>()
        let entities = try modelContext.fetch(descriptor)
        for entity in entities {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }

    public func addBudget(
        id: String,
        amount: Double,
        category: CashlyDomain.Category,
        date: Int,
        summary: String
    ) async throws {
        let predicate: Predicate<BudgetEntity> = #Predicate { $0.id == id }
        let descriptor = FetchDescriptor<BudgetEntity>(predicate: predicate)
        let entity = try modelContext.fetch(descriptor).first ?? BudgetEntity(
            id: id,
            amount: amount,
            category: category.id,
            date: date,
            summary: summary
        )
        entity.id = id
        entity.amount = amount
        entity.category = category.id
        entity.date = date
        entity.summary = summary
        modelContext.insert(entity)
        try modelContext.save()
    }
}
