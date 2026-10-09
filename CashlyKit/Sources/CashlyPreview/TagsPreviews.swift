#if DEBUG
    import FeatureCore
    import FeatureTags
    import SwiftUI

    #Preview("Nova tag") {
        NavigationStack {
            WithSession { session, _, _ in
                ModelHost(TagEditorModel(repositories: session.repositories)) { TagEditorScreen() }
            }
        }
        .cashlyPreview()
    }
#endif
