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

public struct MockCashlyFactory: CashlyDataFactoryProtocol, CashlyPresentationFactoryProtocol {
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
        let state = AddCategoryState()
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
        let state = AddBudgetState()
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
        let state = AddTransactionState()
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
        let state = AddUserState()
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
