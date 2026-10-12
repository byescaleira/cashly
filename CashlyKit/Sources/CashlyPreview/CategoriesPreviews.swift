#if DEBUG
    import FeatureCategories
    import FeatureCore
    import SwiftUI

    #Preview("Metas") {
        NavigationStack {
            WithSession { session, finance, _ in
                ModelHost(GoalsModel(session: session, finance: finance)) { GoalsScreen() }
            }
        }
        .cashlyPreview()
    }

    #Preview("Nova categoria") {
        NavigationStack {
            WithSession { session, _, _ in
                ModelHost(CategoryEditorModel(repositories: session.repositories)) {
                    CategoryEditorScreen()
                }
            }
        }
        .cashlyPreview()
    }
#endif
