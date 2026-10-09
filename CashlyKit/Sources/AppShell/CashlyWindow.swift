import CashlyDomain
import FeatureCore
import FeatureSearch
import FeatureTransactions
import SwiftUI

@MainActor
public struct CashlyWindow {
    public let session: SessionModel
    public let finance: FinanceModel
    public let transactions: TransactionListModel
    public let intelligence: IntelligenceModel
    public let search: SearchModel
    public let navigation: CashlyNavigation

    public init(
        provider: any RepositoryProvider, intelligence service: any IntelligenceService,
        preference: UserPreference = .standard
    ) {
        session = SessionModel(provider: provider, preference: preference)
        finance = FinanceModel(session: session)
        transactions = TransactionListModel(session: session)
        intelligence = IntelligenceModel(service: service, session: session)
        search = SearchModel(session: session, finance: finance)
        navigation = CashlyNavigation()
    }
}

extension View {
    public func cashlyWindow(_ window: CashlyWindow) -> some View {
        environment(window.session)
            .environment(window.finance)
            .environment(window.transactions)
            .environment(window.intelligence)
            .environment(window.search)
            .environment(window.navigation)
            .environment(\.user, window.session.user)
    }
}
