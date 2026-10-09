#if DEBUG
    import FeatureCategories
    import FeatureCore
    import SwiftUI

    #Preview("Categorias") { NavigationStack { CategoryListScreen() }.cashlyPreview() }

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
