//
//  CashlyPresentationFactoryProtocol.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import RyzeArchitecture

public protocol CashlyPresentationFactoryProtocol {
    associatedtype AddCategoryReducer: RyzeReducer
    associatedtype AddCategoryMiddleware: RyzeMiddleware
    
    associatedtype AddBudgetReducer: RyzeReducer
    associatedtype AddBudgetMiddleware: RyzeMiddleware
    
    associatedtype AddTransactionReducer: RyzeReducer
    associatedtype AddTransactionMiddleware: RyzeMiddleware
    
    associatedtype MainReducer: RyzeReducer
    associatedtype MainMiddleware: RyzeMiddleware
    
    associatedtype AddUserReducer: RyzeReducer
    associatedtype AddUserMiddleware: RyzeMiddleware
    
    associatedtype AddTagReducer: RyzeReducer
    associatedtype AddTagMiddleware: RyzeMiddleware
    
    func makeAddCategoryStore() -> RyzeStore<AddCategoryReducer, AddCategoryMiddleware>
    func makeAddBudgetStore() -> RyzeStore<AddBudgetReducer, AddBudgetMiddleware>
    func makeAddTransactionStore() -> RyzeStore<AddTransactionReducer, AddTransactionMiddleware>
    func makeAddUserStore() -> RyzeStore<AddUserReducer, AddUserMiddleware>
    func makeAddTagStore() -> RyzeStore<AddTagReducer, AddTagMiddleware>
    func makeMainStore() -> RyzeStore<MainReducer, MainMiddleware>
}
