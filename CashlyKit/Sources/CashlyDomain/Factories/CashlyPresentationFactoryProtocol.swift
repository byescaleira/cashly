//
//  CashlyPresentationFactoryProtocol.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

public protocol CashlyPresentationFactoryProtocol: Sendable {
    associatedtype AddCategoryReducer: CashlyReducer
    associatedtype AddCategoryMiddleware: CashlyMiddleware
    
    associatedtype AddBudgetReducer: CashlyReducer
    associatedtype AddBudgetMiddleware: CashlyMiddleware
    
    associatedtype AddTransactionReducer: CashlyReducer
    associatedtype AddTransactionMiddleware: CashlyMiddleware
    
    associatedtype MainReducer: CashlyReducer
    associatedtype MainMiddleware: CashlyMiddleware
    
    associatedtype AddUserReducer: CashlyReducer
    associatedtype AddUserMiddleware: CashlyMiddleware
    
    func makeAddCategoryStore() -> CashlyStore<AddCategoryReducer, AddCategoryMiddleware>
    func makeAddBudgetStore() -> CashlyStore<AddBudgetReducer, AddBudgetMiddleware>
    func makeAddTransactionStore() -> CashlyStore<AddTransactionReducer, AddTransactionMiddleware>
    func makeAddUserStore() -> CashlyStore<AddUserReducer, AddUserMiddleware>
    func makeMainStore() -> CashlyStore<MainReducer, MainMiddleware>
}
