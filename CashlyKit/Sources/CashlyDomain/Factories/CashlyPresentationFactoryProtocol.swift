//
//  CashlyPresentationFactoryProtocol.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

public protocol CashlyPresentationFactoryProtocol: Sendable {
    associatedtype AddBudgetReducer: CashlyReducer
    associatedtype AddBudgetMiddleware: CashlyMiddleware
    associatedtype AddCategoryReducer: CashlyReducer
    associatedtype AddCategoryMiddleware: CashlyMiddleware
    
    func makeAddBudgetStore() -> CashlyStore<AddBudgetReducer, AddBudgetMiddleware>
    func makeAddCategoryStore() -> CashlyStore<AddCategoryReducer, AddCategoryMiddleware>
}
