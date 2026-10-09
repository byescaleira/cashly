#if DEBUG
    import AppShell
    import CashlyDomain
    import FeatureCore
    import CashlyMock
    import CashlyUI
    import FeatureCategories
    import FeatureDashboard
    import FeatureTransactions
    import SwiftUI

    #Preview("Cashly") { MainScreen().cashlyPreview() }
    #Preview("Cashly sem perfis") { MainScreen().cashlyPreview(includeSampleData: false) }
    private struct HomePreview: View {
        @Environment(SessionModel.self) var session
        @Environment(FinanceModel.self) var finance
        @Environment(IntelligenceModel.self) var intelligence
        var body: some View {
            ModelHost(
                DashboardModel(session: session, finance: finance, intelligence: intelligence)
            ) {
                HomeScreen()
            }
        }
    }
    #Preview("Início") { NavigationStack { HomePreview().cashlyPreview() } }
    #Preview("Categorias") { NavigationStack { CategoryListScreen().cashlyPreview() } }
    #Preview("Transações") { NavigationStack { TransactionListScreen().cashlyPreview() } }
    private struct NewTransactionPreview: View {
        @Environment(SessionModel.self) var session
        var body: some View {
            ModelHost(TransactionEditorModel(repositories: session.repositories)) {
                TransactionEditorScreen()
            }
        }
    }
    #Preview("Nova transação") { NavigationStack { NewTransactionPreview().cashlyPreview() } }
#endif
