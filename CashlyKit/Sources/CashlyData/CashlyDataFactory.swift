//
//  CashlyDataFactory.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import SwiftData
import CashlyDomain

public struct CashlyDataFactory: @MainActor CashlyDataFactoryProtocol {
    let modelContainer: ModelContainer
    
    @MainActor
    public init() {
        do {
            let schema = Schema(
                BudgetEntity.self,
                CategoryEntity.self,
                TransactionEntity.self,
                UserEntity.self,
                TagEntity.self,
                ParticipantEntity.self
            )
            
            let container = try ModelContainer(
                for: schema,
                configurations: .init(isStoredInMemoryOnly: false)
            )
            
            modelContainer = container
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    @MainActor
    public func makeAdapter() -> AdapterUseCase {
        let modelContext = modelContainer.mainContext
        return AdapterActor(modelContext: modelContext)
    }
    
    @MainActor
    public func makeBudgetUseCase() -> BudgetUseCase {
        let modelContext = modelContainer.mainContext
        let adapter = makeAdapter()
        return BudgetActor(
            modelContext: modelContext,
            adapter: adapter
        )
    }
    
    @MainActor
    public func makeCategoryUseCase() -> CategoryUseCase {
        let modelContext = modelContainer.mainContext
        let adapter = makeAdapter()
        return CategoryActor(
            modelContext: modelContext,
            adapter: adapter
        )
    }
    
    @MainActor
    public func makeUserUseCase() -> UserUseCase {
        let modelContext = modelContainer.mainContext
        let adapter = makeAdapter()
        return UserActor(
            modelContext: modelContext,
            adapter: adapter
        )
    }
    
    @MainActor
    public func makeTransactionUseCase() -> TransactionUseCase {
        let modelContext = modelContainer.mainContext
        let adapter = makeAdapter()
        return TransactionActor(
            modelContext: modelContext,
            adapter: adapter
        )
    }
    
    @MainActor
    public func makeTagUseCase() -> TagUseCase {
        let modelContext = modelContainer.mainContext
        let adapter = makeAdapter()
        return TagActor(
            modelContext: modelContext,
            adapter: adapter
        )
    }
    
    @MainActor
    public func makeParticipantUseCase() -> any ParticipantUseCase {
        let modelContext = modelContainer.mainContext
        let adapter = makeAdapter()
        return ParticipantActor(
            modelContext: modelContext,
            adapter: adapter
        )
    }
}
