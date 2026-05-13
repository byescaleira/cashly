//
//  CashlyDataFactory.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import SwiftData
import CashlyDomain

@MainActor
public struct CashlyDataFactory: CashlyDataFactoryProtocol {
    let modelContainer: ModelContainer
    let userPreferences: UserPreferencesUseCase
    let subscription: SubscriptionUseCase

    public init(
        modelContainer: ModelContainer,
        userPreferences: UserPreferencesUseCase = UserDefaultsUserPreferences(),
        subscription: SubscriptionUseCase = StoreKitSubscriptionService()
    ) {
        self.modelContainer = modelContainer
        self.userPreferences = userPreferences
        self.subscription = subscription
    }

    public static func make() throws -> CashlyDataFactory {
        let schema = Schema(versionedSchema: CashlySchemaV2.self)

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.cashly")
        )

        let container = try ModelContainer(
            for: schema,
            migrationPlan: CashlyMigrationPlan.self,
            configurations: configuration
        )

        return CashlyDataFactory(modelContainer: container)
    }

    public func makeAdapter() -> AdapterUseCase {
        AdapterActor(modelContainer: modelContainer)
    }

    public func makeBudgetUseCase() -> BudgetUseCase {
        BudgetActor(modelContainer: modelContainer)
    }

    public func makeCategoryUseCase() -> CategoryUseCase {
        CategoryActor(modelContainer: modelContainer)
    }

    public func makeUserUseCase() -> UserUseCase {
        UserActor(modelContainer: modelContainer, preferences: userPreferences)
    }

    public func makeUserPreferences() -> UserPreferencesUseCase {
        userPreferences
    }

    public func makeSubscriptionUseCase() -> SubscriptionUseCase {
        subscription
    }

    public func makeFeatureGate() -> FeatureGateUseCase {
        DefaultFeatureGate(
            subscription: subscription,
            userUseCase: makeUserUseCase(),
            categoryUseCase: makeCategoryUseCase(),
            budgetUseCase: makeBudgetUseCase()
        )
    }

    public func makeAppIcon() -> AppIconUseCase {
        #if canImport(UIKit)
        return UIKitAppIconService()
        #else
        return InMemoryAppIconService()
        #endif
    }

    public func makeReachability() -> ReachabilityUseCase {
        NWPathReachabilityService()
    }

    public func makeBudgetAlerts() -> BudgetAlertsUseCase {
        UserNotificationsBudgetAlerts()
    }

    public func makeSyncStatus() -> SyncStatusUseCase {
        UserDefaultsSyncStatus()
    }

    public func makeSpotlightIndexer() -> SpotlightIndexerUseCase {
        #if canImport(CoreSpotlight)
        return CoreSpotlightIndexer()
        #else
        return InMemorySpotlightIndexer()
        #endif
    }

    public func makeFeatureFlags() -> FeatureFlagsUseCase {
        UserDefaultsFeatureFlags()
    }

    public func makeBackgroundRefresh() -> BackgroundRefreshUseCase {
        BGTaskBackgroundRefresh()
    }

    public func makeReceiptValidation() -> ReceiptValidationUseCase {
        // Skeleton — no public backend yet. Returns the stub so
        // production still treats StoreKit's local check as the
        // source of truth until the endpoint ships.
        InMemoryReceiptValidation(stub: .unreachable)
    }

    public func makeAppLock() -> AppLockUseCase {
        LocalAuthenticationAppLock()
    }

    public func makeTransactionDictation() -> TransactionDictationUseCase {
        // K2a: prefer the on-device Foundation Models parser when
        // the OS supports it. The impl probes runtime availability
        // (Apple Intelligence may be disabled) and falls back to the
        // keyword stub draft when the model can't run.
        #if canImport(FoundationModels)
        if #available(iOS 18.1, macOS 15.1, *) {
            return FoundationModelsTransactionDictation()
        }
        #endif
        return KeywordTransactionDictation()
    }

    public func makeTransactionUseCase() -> TransactionUseCase {
        TransactionActor(modelContainer: modelContainer)
    }

    public func makeTagUseCase() -> TagUseCase {
        TagActor(modelContainer: modelContainer)
    }

    public func makeParticipantUseCase() -> any ParticipantUseCase {
        ParticipantActor(modelContainer: modelContainer)
    }
}
