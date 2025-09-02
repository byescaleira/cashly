//
//  MockCashlyFactory.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import SwiftData
import CashlyDomain
import CashlyData

public struct MockCashlyFactory: CashlyDataFactoryProtocol {
    let modelContainer: ModelContainer
    
    public init() throws {
        let schema = Schema(
            BudgetEntity.self,
            CategoryEntity.self
        )
        
        let container = try ModelContainer(
            for: schema,
            configurations: .init(isStoredInMemoryOnly: true)
        )
        modelContainer = container
    }
    
    public func makeModelContext() -> ModelContext {
        ModelContext(modelContainer)
    }
    
    public func makeAdapter() -> AdapterUseCase {
        let modelContext = makeModelContext()
        return AdapterActor(modelContext: modelContext)
    }
    
    public func makeBudgetUseCase() -> BudgetUseCase {
        let modelContext = makeModelContext()
        let adapter = makeAdapter()
        return BudgetActor(
            modelContext: modelContext,
            adapter: adapter
        )
    }
    
    public func makeCategoryUseCase() -> CategoryUseCase {
        let modelContext = makeModelContext()
        let adapter = makeAdapter()
        return CategoryActor(
            modelContext: modelContext,
            adapter: adapter
        )
    }
    
    public func makeUserUseCase() -> UserUseCase {
        let modelContext = makeModelContext()
        let adapter = makeAdapter()
        return UserActor(
            modelContext: modelContext,
            adapter: adapter
        )
    }
    
    public func makeTransactionUseCase() -> TransactionUseCase {
        let modelContext = makeModelContext()
        let adapter = makeAdapter()
        return TransactionActor(
            modelContext: modelContext,
            adapter: adapter
        )
    }
}
