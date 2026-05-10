//
//  MockCashlyFactory.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import SwiftData
import CashlyDomain
import CashlyData
import CashlyPresentation
import RyzeArchitecture

public struct MockCashlyFactory: CashlyDataFactoryProtocol, CashlyPresentationFactoryProtocol {
    let modelContainer: ModelContainer

    @MainActor
    public init() {
        // In-memory container init can only fail if SwiftData itself is
        // misconfigured at compile time. Treat as programmer error.
        // G005 (Wave 4 target): kill singleton + throw at composition root.
        let schema = Schema(
            BudgetEntity.self,
            CategoryEntity.self,
            TransactionEntity.self,
            UserEntity.self,
            TagEntity.self,
            ParticipantEntity.self
        )
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: .init(isStoredInMemoryOnly: true)
            )
        } catch {
            preconditionFailure("MockCashlyFactory in-memory bootstrap failed: \(error.localizedDescription)")
        }
    }
    
    public func makeModelContext() -> ModelContext {
        ModelContext(modelContainer)
    }
    
    public func makeAdapter() -> AdapterUseCase {
        MockAdapterActor()
    }
    
    public func makeBudgetUseCase() -> BudgetUseCase {
        MockBudgetActor()
    }
    
    public func makeCategoryUseCase() -> CategoryUseCase {
        MockCategoryActor()
    }
    
    public func makeUserUseCase() -> UserUseCase {
        MockUserActor()
    }
    
    public func makeTransactionUseCase() -> TransactionUseCase {
        MockTransactionActor()
    }
    
    public func makeTagUseCase() -> any TagUseCase {
        MockTagActor()
    }
    
    public func makeParticipantUseCase() -> any ParticipantUseCase {
        MockParticipantActor()
    }
    
    public func makeAddCategoryStore() -> CashlyStore<AddCategoryReducer, AddCategoryMiddleware> {
        let state = AddCategoryState.new()
        let reducer = AddCategoryReducer()
        let budgetUseCase = makeBudgetUseCase()
        let categoryUseCase = makeCategoryUseCase()
        let transactionUseCase = makeTransactionUseCase()
        let userUseCase = makeUserUseCase()
        let middleware = AddCategoryMiddleware(
            budgetUseCase: budgetUseCase,
            categoryUseCase: categoryUseCase,
            transactionUseCase: transactionUseCase,
            userUseCase: userUseCase
        )
        return .init(
            state: state,
            reducer: reducer,
            middleware: middleware
        )
    }
    
    public func makeAddBudgetStore() -> CashlyStore<AddBudgetReducer, AddBudgetMiddleware> {
        let state = AddBudgetState.new()
        let reducer = AddBudgetReducer()
        let budgetUseCase = makeBudgetUseCase()
        let categoryUseCase = makeCategoryUseCase()
        let transactionUseCase = makeTransactionUseCase()
        let userUseCase = makeUserUseCase()
        let middleware = AddBudgetMiddleware(
            budgetUseCase: budgetUseCase,
            categoryUseCase: categoryUseCase,
            transactionUseCase: transactionUseCase,
            userUseCase: userUseCase
        )
        return .init(
            state: state,
            reducer: reducer,
            middleware: middleware
        )
    }
    
    public func makeAddTransactionStore() -> CashlyStore<AddTransactionReducer, AddTransactionMiddleware> {
        let state = AddTransactionState.new()
        let reducer = AddTransactionReducer()
        let budgetUseCase = makeBudgetUseCase()
        let categoryUseCase = makeCategoryUseCase()
        let transactionUseCase = makeTransactionUseCase()
        let tagUseCase = makeTagUseCase()
        let userUseCase = makeUserUseCase()
        let participantUseCase = makeParticipantUseCase()
        let middleware = AddTransactionMiddleware(
            budgetUseCase: budgetUseCase,
            categoryUseCase: categoryUseCase,
            transactionUseCase: transactionUseCase,
            tagUseCase: tagUseCase,
            userUseCase: userUseCase,
            participantUseCase: participantUseCase
        )
        return .init(
            state: state,
            reducer: reducer,
            middleware: middleware
        )
    }
    
    public func makeAddUserStore() -> CashlyStore<AddUserReducer, AddUserMiddleware> {
        let state = AddUserState.new()
        let reducer = AddUserReducer()
        let budgetUseCase = makeBudgetUseCase()
        let categoryUseCase = makeCategoryUseCase()
        let transactionUseCase = makeTransactionUseCase()
        let userUseCase = makeUserUseCase()
        let middleware = AddUserMiddleware(
            budgetUseCase: budgetUseCase,
            categoryUseCase: categoryUseCase,
            transactionUseCase: transactionUseCase,
            userUseCase: userUseCase
        )
        return .init(
            state: state,
            reducer: reducer,
            middleware: middleware
        )
    }
    
    public func makeAddTagStore() -> CashlyStore<AddTagReducer, AddTagMiddleware> {
        let state = AddTagState.new()
        let reducer = AddTagReducer()
        let tagUseCase = makeTagUseCase()
        let userUseCase = makeUserUseCase()
        let middleware = AddTagMiddleware(
            tagUseCase: tagUseCase,
            userUseCase: userUseCase
        )
        return .init(
            state: state,
            reducer: reducer,
            middleware: middleware
        )
    }
    
    public func makeMainStore() -> CashlyStore<MainReducer, MainMiddleware> {
        let state = MainState()
        let reducer = MainReducer()
        let budgetUseCase = makeBudgetUseCase()
        let categoryUseCase = makeCategoryUseCase()
        let transactionUseCase = makeTransactionUseCase()
        let tagUseCase = makeTagUseCase()
        let userUseCase = makeUserUseCase()
        let middleware = MainMiddleware(
            budgetUseCase: budgetUseCase,
            categoryUseCase: categoryUseCase,
            transactionUseCase: transactionUseCase,
            tagUseCase: tagUseCase,
            userUseCase: userUseCase
        )
        return .init(
            state: state,
            reducer: reducer,
            middleware: middleware
        )
    }
}
