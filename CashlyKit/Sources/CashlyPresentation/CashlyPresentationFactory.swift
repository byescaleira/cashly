//
//  CashlyPresentationFactory.swift
//  CashlyKit
//

import Foundation

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

    public func makeSyncStatus() -> SyncStatusUseCase {
        dataFactory.makeSyncStatus()
    }

    public func makeSpotlightIndexer() -> SpotlightIndexerUseCase {
        dataFactory.makeSpotlightIndexer()
    }

    public func makeAppLock() -> AppLockUseCase {
        dataFactory.makeAppLock()
    }

    public func makeTransactionDictation() -> TransactionDictationUseCase {
        dataFactory.makeTransactionDictation()
    }

    public func makeSpeechTranscriber() -> SpeechTranscriberUseCase {
        dataFactory.makeSpeechTranscriber()
    }

    public func makeAttachmentStorage() -> AttachmentStorageUseCase {
        dataFactory.makeAttachmentStorage()
    }

    public func makeRecurringTransactions() -> RecurringTransactionUseCase {
        dataFactory.makeRecurringTransactions()
    }

    public func makeTransactionUseCase() -> TransactionUseCase {
        dataFactory.makeTransactionUseCase()
    }

    public func makeBudgetUseCase() -> BudgetUseCase {
        dataFactory.makeBudgetUseCase()
    }

    public func makeCategoryUseCase() -> CategoryUseCase {
        dataFactory.makeCategoryUseCase()
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
                budgetAlerts: dataFactory.makeBudgetAlerts(),
                spotlight: dataFactory.makeSpotlightIndexer(),
                watchSync: dataFactory.makeWatchSync(),
                // Persisted user-tunable threshold. UI exposes it
                // as a percent; we store the fraction (0–1).
                overshootThreshold: Self.persistedOvershootThreshold()
            )
        )
    }

    private static func persistedOvershootThreshold(
        suite: UserDefaults = .standard
    ) -> Double {
        let raw = suite.double(forKey: "cashly.budgetAlerts.overshoot")
        // UserDefaults returns 0 when the key is absent — fall back
        // to the historical 0.8 default in that case.
        return raw > 0 ? raw : 0.8
    }
}
