//
//  CashlyDataFactoryProtocol.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

@MainActor
public protocol CashlyDataFactoryProtocol {
    func makeAdapter() -> AdapterUseCase
    func makeBudgetUseCase() -> BudgetUseCase
    func makeCategoryUseCase() -> CategoryUseCase
    func makeUserUseCase() -> UserUseCase
    func makeUserPreferences() -> UserPreferencesUseCase
    func makeSubscriptionUseCase() -> SubscriptionUseCase
    func makeFeatureGate() -> FeatureGateUseCase
    func makeAppIcon() -> AppIconUseCase
    func makeReachability() -> ReachabilityUseCase
    func makeBudgetAlerts() -> BudgetAlertsUseCase
    func makeSyncStatus() -> SyncStatusUseCase
    func makeSpotlightIndexer() -> SpotlightIndexerUseCase
    func makeFeatureFlags() -> FeatureFlagsUseCase
    func makeBackgroundRefresh() -> BackgroundRefreshUseCase
    func makeReceiptValidation() -> ReceiptValidationUseCase
    func makeAppLock() -> AppLockUseCase
    func makeTransactionDictation() -> TransactionDictationUseCase
    func makeTransactionUseCase() -> TransactionUseCase
    func makeTagUseCase() -> TagUseCase
    func makeParticipantUseCase() -> ParticipantUseCase
}
