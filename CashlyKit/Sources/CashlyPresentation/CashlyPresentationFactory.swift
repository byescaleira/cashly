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
    
    public init() {
        do {
            self.dataFactory = try CashlyDataFactory()
        } catch {
            fatalError()
        }
    }
    
    public func makeAddBudgetStore() -> CashlyStore<AddBudgetReducer, AddBudgetMiddleware> {
        let state = AddBudgetState()
        let reducer = AddBudgetReducer()
        let budgetUseCase = dataFactory.makeBudgetUseCase()
        let categoryUseCase = dataFactory.makeCategoryUseCase()
        let transactionUseCase = dataFactory.makeTransactionUseCase()
        let middleware = AddBudgetMiddleware(
            budgetUseCase: budgetUseCase,
            categoryUseCase: categoryUseCase,
            transactionUseCase: transactionUseCase
        )
        return .init(
            state: state,
            reducer: reducer,
            middleware: middleware
        )
    }
    
    public func makeAddCategoryStore() -> CashlyStore<AddCategoryReducer, AddCategoryMiddleware> {
        let state = AddCategoryState()
        let reducer = AddCategoryReducer()
        let categoryUseCase = dataFactory.makeCategoryUseCase()
        let transactionUseCase = dataFactory.makeTransactionUseCase()
        let middleware = AddCategoryMiddleware(
            categoryUseCase: categoryUseCase,
            transactionUseCase: transactionUseCase
        )
        return .init(
            state: state,
            reducer: reducer,
            middleware: middleware
        )
    }
}
