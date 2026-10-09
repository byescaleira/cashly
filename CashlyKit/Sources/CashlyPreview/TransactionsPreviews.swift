#if DEBUG
    import FeatureCore
    import FeatureTransactions
    import SwiftUI

    #Preview("Transações") { NavigationStack { TransactionListScreen() }.cashlyPreview() }

    #Preview("Nova transação") {
        NavigationStack {
            WithSession { session, _, _ in
                ModelHost(TransactionEditorModel(repositories: session.repositories)) {
                    TransactionEditorScreen()
                }
            }
        }
        .cashlyPreview()
    }
#endif
