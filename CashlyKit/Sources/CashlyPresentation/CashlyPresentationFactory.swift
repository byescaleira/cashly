//
//  CashlyPresentationFactory.swift
//  CashlyKit
//

import CashlyDomain
import CashlyData
import CashlyResource
import PrismArchitecture

@MainActor
public struct CashlyPresentationFactory: CashlyPresentationFactoryProtocol {
    let dataFactory: CashlyDataFactoryProtocol
    let analytics: AnalyticsTracker

    public init(
        dataFactory: CashlyDataFactoryProtocol,
        analytics: AnalyticsTracker = OSLogAnalyticsTracker()
    ) {
        self.dataFactory = dataFactory
        self.analytics = analytics
    }

    public init() throws {
        self.dataFactory = try CashlyDataFactory.make()
        self.analytics = OSLogAnalyticsTracker()
    }

    /// Subscription service for the app delegate to wire up the
    /// `Transaction.updates` listener at launch.
    public func makeSubscriptionUseCase() -> SubscriptionUseCase {
        dataFactory.makeSubscriptionUseCase()
    }

    /// Reachability monitor for the app delegate to forward into
    /// MainState via `.main(.reachabilityUpdated(_:))`.
    public func makeReachability() -> ReachabilityUseCase {
        dataFactory.makeReachability()
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
                subscription: dataFactory.makeSubscriptionUseCase(),
                analytics: analytics
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
                userUseCase: dataFactory.makeUserUseCase(),
                userPreferences: dataFactory.makeUserPreferences(),
                budgetAlerts: dataFactory.makeBudgetAlerts()
            )
        )
    }
}
