//
//  CashlyPresentationFactoryProtocol.swift
//  CashlyKit
//

import PrismArchitecture

@MainActor
public protocol CashlyPresentationFactoryProtocol {
    func makeAddCategoryStore() -> CashlyStore<AddCategoryState, AddCategoryAction>
    func makeAddBudgetStore() -> CashlyStore<AddBudgetState, AddBudgetAction>
    func makeAddTransactionStore() -> CashlyStore<AddTransactionState, AddTransactionAction>
    func makeAddUserStore() -> CashlyStore<AddUserState, AddUserAction>
    func makeAddTagStore() -> CashlyStore<AddTagState, AddTagAction>
    func makeMainStore() -> CashlyStore<MainState, MainAction>
}
