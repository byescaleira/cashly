//
//  MockCashlyFactory.swift
//  CashlyKit
//

import SwiftData
import CashlyDomain
import CashlyData
import CashlyPresentation
import PrismArchitecture

@MainActor
public struct MockCashlyFactory: CashlyDataFactoryProtocol, CashlyPresentationFactoryProtocol {
    let modelContainer: ModelContainer

    public init() {
        let schema = Schema(
            BudgetEntity.self,
            CategoryEntity.self,
            TransactionEntity.self,
            UserEntity.self,
            TagEntity.self,
            ParticipantEntity.self
        )
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: .init(isStoredInMemoryOnly: true)
            )
        } catch {
            preconditionFailure("MockCashlyFactory in-memory bootstrap failed: \(error.localizedDescription)")
        }
    }

    public func makeModelContext() -> ModelContext { ModelContext(modelContainer) }
    public func makeAdapter() -> AdapterUseCase { MockAdapterActor() }
    public func makeBudgetUseCase() -> BudgetUseCase { MockBudgetActor() }
    public func makeCategoryUseCase() -> CategoryUseCase { MockCategoryActor() }
    public func makeUserUseCase() -> UserUseCase { MockUserActor() }
    public func makeUserPreferences() -> UserPreferencesUseCase { InMemoryUserPreferences() }
    public func makeSubscriptionUseCase() -> SubscriptionUseCase { InMemorySubscriptionService() }
    public func makeFeatureGate() -> FeatureGateUseCase { AlwaysAllowedFeatureGate() }
    public func makeAppIcon() -> AppIconUseCase { InMemoryAppIconService() }
    public func makeReachability() -> ReachabilityUseCase { InMemoryReachabilityService() }
    public func makeBudgetAlerts() -> BudgetAlertsUseCase { InMemoryBudgetAlerts() }
    public func makeSyncStatus() -> SyncStatusUseCase { InMemorySyncStatus() }
    public func makeSpotlightIndexer() -> SpotlightIndexerUseCase { InMemorySpotlightIndexer() }
    public func makeFeatureFlags() -> FeatureFlagsUseCase { InMemoryFeatureFlags() }
    public func makeBackgroundRefresh() -> BackgroundRefreshUseCase { InMemoryBackgroundRefresh() }
    public func makeReceiptValidation() -> ReceiptValidationUseCase { InMemoryReceiptValidation() }
    public func makeAppLock() -> AppLockUseCase { InMemoryAppLock() }
    public func makeTransactionUseCase() -> TransactionUseCase { MockTransactionActor() }
    public func makeTagUseCase() -> any TagUseCase { MockTagActor() }
    public func makeParticipantUseCase() -> any ParticipantUseCase { MockParticipantActor() }

    public func makeAddCategoryStore() -> CashlyStore<AddCategoryState, AddCategoryAction> {
        CashlyStore(
            initialState: .new(),
            reducer: AddCategoryReducer(),
            middleware: AddCategoryMiddleware(
                budgetUseCase: makeBudgetUseCase(),
                categoryUseCase: makeCategoryUseCase(),
                transactionUseCase: makeTransactionUseCase(),
                userUseCase: makeUserUseCase(),
                featureGate: makeFeatureGate()
            )
        )
    }

    public func makeAddBudgetStore() -> CashlyStore<AddBudgetState, AddBudgetAction> {
        CashlyStore(
            initialState: .new(),
            reducer: AddBudgetReducer(),
            middleware: AddBudgetMiddleware(
                budgetUseCase: makeBudgetUseCase(),
                categoryUseCase: makeCategoryUseCase(),
                transactionUseCase: makeTransactionUseCase(),
                userUseCase: makeUserUseCase(),
                featureGate: makeFeatureGate()
            )
        )
    }

    public func makeAddTransactionStore() -> CashlyStore<AddTransactionState, AddTransactionAction> {
        CashlyStore(
            initialState: .new(),
            reducer: AddTransactionReducer(),
            middleware: AddTransactionMiddleware(
                budgetUseCase: makeBudgetUseCase(),
                categoryUseCase: makeCategoryUseCase(),
                transactionUseCase: makeTransactionUseCase(),
                tagUseCase: makeTagUseCase(),
                userUseCase: makeUserUseCase(),
                participantUseCase: makeParticipantUseCase()
            )
        )
    }

    public func makeAddUserStore() -> CashlyStore<AddUserState, AddUserAction> {
        CashlyStore(
            initialState: .new(),
            reducer: AddUserReducer(),
            middleware: AddUserMiddleware(
                budgetUseCase: makeBudgetUseCase(),
                categoryUseCase: makeCategoryUseCase(),
                transactionUseCase: makeTransactionUseCase(),
                userUseCase: makeUserUseCase(),
                featureGate: makeFeatureGate()
            )
        )
    }

    public func makeAddTagStore() -> CashlyStore<AddTagState, AddTagAction> {
        CashlyStore(
            initialState: .new(),
            reducer: AddTagReducer(),
            middleware: AddTagMiddleware(
                tagUseCase: makeTagUseCase(),
                userUseCase: makeUserUseCase()
            )
        )
    }

    public func makePaywallStore(trigger: PaywallTrigger) -> CashlyStore<PaywallState, PaywallAction> {
        CashlyStore(
            initialState: .opened(from: trigger),
            reducer: PaywallReducer(),
            middleware: PaywallMiddleware(
                subscription: makeSubscriptionUseCase()
            )
        )
    }

    public func makeMainStore() -> CashlyStore<MainState, MainAction> {
        CashlyStore(
            initialState: MainState(),
            reducer: MainReducer(),
            middleware: MainMiddleware(
                budgetUseCase: makeBudgetUseCase(),
                categoryUseCase: makeCategoryUseCase(),
                transactionUseCase: makeTransactionUseCase(),
                tagUseCase: makeTagUseCase(),
                userUseCase: makeUserUseCase(),
                userPreferences: makeUserPreferences(),
                budgetAlerts: makeBudgetAlerts(),
                spotlight: makeSpotlightIndexer()
            )
        )
    }
}
