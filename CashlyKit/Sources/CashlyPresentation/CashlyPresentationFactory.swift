//
//  CashlyPresentationFactory.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import CashlyDomain
import CashlyData

public struct CashlyPresentationFactory: CashlyPresentationFactoryProtocol {
    let dataFactory: CashlyDataFactoryProtocol
    
    public init(dataFactory: CashlyDataFactoryProtocol) {
        self.dataFactory = dataFactory
    }
    
    public func makeAddCategoryStore() -> CashlyStore<AddCategoryReducer, AddCategoryMiddleware> {
        let state = AddCategoryState()
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
    
    public func makeAddBudgetStore() -> CashlyStore<AddBudgetReducer, AddBudgetMiddleware> {
        let state = AddBudgetState()
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
    
    public func makeAddTransactionStore() -> CashlyStore<AddTransactionReducer, AddTransactionMiddleware> {
        let state = AddTransactionState()
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
    
    public func makeAddUserStore() -> RyzeStore<AddUserReducer, AddUserMiddleware> {
        let state = AddUserState()
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
