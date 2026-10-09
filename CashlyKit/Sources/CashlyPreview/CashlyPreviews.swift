#if DEBUG
    import AppShell
    import CashlyDomain
    import CashlyPresentation
    import FeatureCore
    import CashlyMock
    import CashlyUI
    import FeatureCategories
    import SwiftUI

    #Preview("Cashly") { MainScreen().cashlyPreview() }
    #Preview("Cashly sem perfis") { MainScreen().cashlyPreview(includeSampleData: false) }
    #Preview("Início") { NavigationStack { HomeScreen().cashlyPreview() } }
    #Preview("Categorias") { NavigationStack { CategoryListScreen().cashlyPreview() } }
    #Preview("Transações") { NavigationStack { TransactionScreen().cashlyPreview() } }
    private struct NewTransactionPreview: View {
        @Environment(SessionModel.self) var session
        var body: some View {
            ModelHost(TransactionEditorModel(repositories: session.repositories)) {
                AddTransactionScreen()
            }
        }
    }
    #Preview("Nova transação") { NavigationStack { NewTransactionPreview().cashlyPreview() } }
#endif
