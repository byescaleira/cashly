#if DEBUG
    import CashlyDomain
    import CashlyPresentation
    import CashlyMock
    import CashlyUI
    import SwiftUI

    #Preview("Cashly") { MainScreen().cashlyPreview() }
    #Preview("Cashly sem perfis") { MainScreen().cashlyPreview(includeSampleData: false) }
    #Preview("Início") { NavigationStack { HomeScreen().cashlyPreview() } }
    #Preview("Categorias") { NavigationStack { CategoryScreen().cashlyPreview() } }
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
