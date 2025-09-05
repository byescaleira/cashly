//
//  CashlyDataFactory.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import SwiftData
import CashlyDomain

public struct CashlyDataFactory: CashlyDataFactoryProtocol {
    let modelContainer: ModelContainer
    
    public init() {
        do {
            let schema = Schema(
                BudgetEntity.self,
                CategoryEntity.self,
                TransactionEntity.self,
                UserEntity.self
            )
            
            let container = try ModelContainer(
                for: schema,
                configurations: .init(isStoredInMemoryOnly: true)
            )
            modelContainer = container
        } catch {
            fatalError(error.localizedDescription)
        }
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
    
    public func makeTagUseCase() -> TagUseCase {
        let modelContext = makeModelContext()
        let adapter = makeAdapter()
        return TagActor(
            modelContext: modelContext,
            adapter: adapter
        )
    }
    
    public func makeParticipantUseCase() -> any ParticipantUseCase {
        let modelContext = makeModelContext()
        let adapter = makeAdapter()
        return ParticipantActor(
            modelContext: modelContext,
            adapter: adapter
        )
    }
}
