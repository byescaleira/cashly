#if DEBUG
    import FeatureBudgets
    import FeatureCore
    import SwiftUI

    #Preview("Novo orçamento") {
        NavigationStack {
            WithSession { session, _, _ in
                ModelHost(BudgetEditorModel(repositories: session.repositories)) {
                    BudgetEditorScreen()
                }
            }
        }
        .cashlyPreview()
    }
#endif
