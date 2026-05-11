//
//  CashlyDataFactory.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import SwiftData
import CashlyDomain

@MainActor
public struct CashlyDataFactory: CashlyDataFactoryProtocol {
    let modelContainer: ModelContainer

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    public static func make() throws -> CashlyDataFactory {
        let schema = Schema(
            BudgetEntity.self,
            CategoryEntity.self,
            TransactionEntity.self,
            UserEntity.self,
            TagEntity.self,
            ParticipantEntity.self
        )

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.cashly")
        )

        let container = try ModelContainer(
            for: schema,
            configurations: configuration
        )

        return CashlyDataFactory(modelContainer: container)
    }
    
    public func makeAdapter() -> AdapterUseCase {
        AdapterActor(modelContainer: modelContainer)
    }
    
    public func makeBudgetUseCase() -> BudgetUseCase {
        BudgetActor(modelContainer: modelContainer)
    }
    
    public func makeCategoryUseCase() -> CategoryUseCase {
        CategoryActor(modelContainer: modelContainer)
    }
    
    public func makeUserUseCase() -> UserUseCase {
        UserActor(modelContainer: modelContainer)
    }
    
    public func makeTransactionUseCase() -> TransactionUseCase {
        TransactionActor(modelContainer: modelContainer)
    }
    
    public func makeTagUseCase() -> TagUseCase {
        TagActor(modelContainer: modelContainer)
    }
    
    public func makeParticipantUseCase() -> any ParticipantUseCase {
        ParticipantActor(modelContainer: modelContainer)
    }
}
