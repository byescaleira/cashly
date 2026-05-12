//
//  CashlyPresentationFactory.swift
//  CashlyKit
//

import CashlyDomain
import CashlyData
import PrismArchitecture

@MainActor
public struct CashlyPresentationFactory: CashlyPresentationFactoryProtocol {
    let dataFactory: CashlyDataFactoryProtocol

    public init(dataFactory: CashlyDataFactoryProtocol) {
        self.dataFactory = dataFactory
    }

    public init() throws {
        self.dataFactory = try CashlyDataFactory.make()
    }

    /// Subscription service for the app delegate to wire up the
    /// `Transaction.updates` listener at launch.
    public func makeSubscriptionUseCase() -> SubscriptionUseCase {
        dataFactory.makeSubscriptionUseCase()
    }

    public func makeAddCategoryStore() -> CashlyStore<AddCategoryState, AddCategoryAction> {
        CashlyStore(
            initialState: .new(),
            reducer: AddCategoryReducer(),
            middleware: AddCategoryMiddleware(
                budgetUseCase: dataFactory.makeBudgetUseCase(),
                categoryUseCase: dataFactory.makeCategoryUseCase(),
                transactionUseCase: dataFactory.makeTransactionUseCase(),
                userUseCase: dataFactory.makeUserUseCase(),
                featureGate: dataFactory.makeFeatureGate()
            )
        )
    }

    public func makeAddBudgetStore() -> CashlyStore<AddBudgetState, AddBudgetAction> {
        CashlyStore(
            initialState: .new(),
            reducer: AddBudgetReducer(),
            middleware: AddBudgetMiddleware(
                budgetUseCase: dataFactory.makeBudgetUseCase(),
                categoryUseCase: dataFactory.makeCategoryUseCase(),
                transactionUseCase: dataFactory.makeTransactionUseCase(),
                userUseCase: dataFactory.makeUserUseCase(),
                featureGate: dataFactory.makeFeatureGate()
            )
        )
    }

    public func makeAddTransactionStore() -> CashlyStore<AddTransactionState, AddTransactionAction> {
        CashlyStore(
            initialState: .new(),
            reducer: AddTransactionReducer(),
            middleware: AddTransactionMiddleware(
                budgetUseCase: dataFactory.makeBudgetUseCase(),
                categoryUseCase: dataFactory.makeCategoryUseCase(),
                transactionUseCase: dataFactory.makeTransactionUseCase(),
                tagUseCase: dataFactory.makeTagUseCase(),
                userUseCase: dataFactory.makeUserUseCase(),
                participantUseCase: dataFactory.makeParticipantUseCase()
            )
        )
    }

    public func makeAddUserStore() -> CashlyStore<AddUserState, AddUserAction> {
        CashlyStore(
            initialState: .new(),
            reducer: AddUserReducer(),
            middleware: AddUserMiddleware(
                budgetUseCase: dataFactory.makeBudgetUseCase(),
                categoryUseCase: dataFactory.makeCategoryUseCase(),
                transactionUseCase: dataFactory.makeTransactionUseCase(),
                userUseCase: dataFactory.makeUserUseCase(),
                featureGate: dataFactory.makeFeatureGate()
            )
        )
    }

    public func makeAddTagStore() -> CashlyStore<AddTagState, AddTagAction> {
        CashlyStore(
            initialState: .new(),
            reducer: AddTagReducer(),
            middleware: AddTagMiddleware(
                tagUseCase: dataFactory.makeTagUseCase(),
                userUseCase: dataFactory.makeUserUseCase()
            )
        )
    }

    public func makePaywallStore(trigger: PaywallTrigger) -> CashlyStore<PaywallState, PaywallAction> {
        CashlyStore(
            initialState: .opened(from: trigger),
            reducer: PaywallReducer(),
            middleware: PaywallMiddleware(
                subscription: dataFactory.makeSubscriptionUseCase()
            )
        )
    }

    public func makeMainStore() -> CashlyStore<MainState, MainAction> {
        CashlyStore(
            initialState: MainState(),
            reducer: MainReducer(),
            middleware: MainMiddleware(
                budgetUseCase: dataFactory.makeBudgetUseCase(),
                categoryUseCase: dataFactory.makeCategoryUseCase(),
                transactionUseCase: dataFactory.makeTransactionUseCase(),
                tagUseCase: dataFactory.makeTagUseCase(),
                userUseCase: dataFactory.makeUserUseCase()
            )
        )
    }
}
