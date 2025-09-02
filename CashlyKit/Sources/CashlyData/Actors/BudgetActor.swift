//
//  BudgetActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import RyzeFoundation
import CashlyDomain
import SwiftData

public actor BudgetActor: BudgetUseCase {
    let modelContext: ModelContext
    let adapter: AdapterUseCase
    
    public init(
        modelContext: ModelContext,
        adapter: AdapterUseCase
    ) {
        self.modelContext = modelContext
        self.adapter = adapter
    }
    
    public func getBudget(id: UUID) async throws -> Budget? {
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
    
    public func removeBudget(id: UUID) async throws {
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
        id: UUID,
        amount: Double,
        category: CashlyDomain.Category,
        date: Date,
        summary: String
    ) async throws {
        let entity = BudgetEntity(
            id: id,
            amount: amount,
            category: category.id,
            date: date.timeIntervalSince1970,
            summary: summary
        )
        modelContext.insert(entity)
        try modelContext.save()
    }
}
