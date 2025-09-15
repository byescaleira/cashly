//
//  CashlyPresentationFactory.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import CashlyDomain
import CashlyData
import RyzeArchitecture

public struct CashlyPresentationFactory: @MainActor CashlyPresentationFactoryProtocol {
    @MainActor
    let dataFactory: CashlyDataFactoryProtocol
    
    @MainActor
    public static let shared = CashlyPresentationFactory()
    
    @MainActor
    public init() {
        self.dataFactory = CashlyDataFactory()
    }
    
    @MainActor
    public func makeAddCategoryStore() -> CashlyStore<AddCategoryReducer, AddCategoryMiddleware> {
        let state = AddCategoryState.new()
        let reducer = AddCategoryReducer()
        let budgetUseCase = dataFactory.makeBudgetUseCase()
        let categoryUseCase = dataFactory.makeCategoryUseCase()
        let transactionUseCase = dataFactory.makeTransactionUseCase()
        let userUseCase = dataFactory.makeUserUseCase()
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
    
    @MainActor
    public func makeAddBudgetStore() -> CashlyStore<AddBudgetReducer, AddBudgetMiddleware> {
        let state = AddBudgetState.new()
        let reducer = AddBudgetReducer()
        let budgetUseCase = dataFactory.makeBudgetUseCase()
        let categoryUseCase = dataFactory.makeCategoryUseCase()
        let transactionUseCase = dataFactory.makeTransactionUseCase()
        let userUseCase = dataFactory.makeUserUseCase()
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
    
    @MainActor
    public func makeAddTransactionStore() -> CashlyStore<AddTransactionReducer, AddTransactionMiddleware> {
        let state = AddTransactionState.new()
        let reducer = AddTransactionReducer()
        let budgetUseCase = dataFactory.makeBudgetUseCase()
        let categoryUseCase = dataFactory.makeCategoryUseCase()
        let transactionUseCase = dataFactory.makeTransactionUseCase()
        let tagUseCase = dataFactory.makeTagUseCase()
        let userUseCase = dataFactory.makeUserUseCase()
        let participantUseCase = dataFactory.makeParticipantUseCase()
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
    
    @MainActor
    public func makeAddUserStore() -> RyzeStore<AddUserReducer, AddUserMiddleware> {
        let state = AddUserState.new()
        let reducer = AddUserReducer()
        let budgetUseCase = dataFactory.makeBudgetUseCase()
        let categoryUseCase = dataFactory.makeCategoryUseCase()
        let transactionUseCase = dataFactory.makeTransactionUseCase()
        let userUseCase = dataFactory.makeUserUseCase()
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
    
    @MainActor
    public func makeAddTagStore() -> CashlyStore<AddTagReducer, AddTagMiddleware> {
        let state = AddTagState.new()
        let reducer = AddTagReducer()
        let tagUseCase = dataFactory.makeTagUseCase()
        let userUseCase = dataFactory.makeUserUseCase()
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
    
    @MainActor
    public func makeMainStore() -> CashlyStore<MainReducer, MainMiddleware> {
        let state = MainState()
        let reducer = MainReducer()
        let budgetUseCase = dataFactory.makeBudgetUseCase()
        let categoryUseCase = dataFactory.makeCategoryUseCase()
        let transactionUseCase = dataFactory.makeTransactionUseCase()
        let tagUseCase = dataFactory.makeTagUseCase()
        let userUseCase = dataFactory.makeUserUseCase()
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
