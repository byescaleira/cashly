import CashlyDomain
import FeatureCore
import FeatureStore
import FeatureTransactions
import SwiftUI

@MainActor
public struct CashlyWindow {
    public let session: SessionModel
    public let finance: FinanceModel
    public let transactions: TransactionListModel
    public let intelligence: IntelligenceModel
    public let store: StoreModel
    public let navigation: CashlyNavigation

    public init(
        provider: any RepositoryProvider, intelligence service: any IntelligenceService,
        preference: UserPreference = .standard, flags: FeatureFlags? = nil
    ) {
        session = SessionModel(provider: provider, preference: preference)
        finance = FinanceModel(session: session)
        transactions = TransactionListModel(session: session)
        intelligence = IntelligenceModel(service: service, session: session, flags: flags)
        store = StoreModel(session: session)
        navigation = CashlyNavigation()
    }
}

extension View {
    public func cashlyWindow(_ window: CashlyWindow) -> some View {
        environment(window.session)
            .environment(window.finance)
            .environment(window.transactions)
            .environment(window.intelligence)
            .environment(window.store)
            .environment(window.navigation)
            .environment(\.user, window.session.user)
    }
}
