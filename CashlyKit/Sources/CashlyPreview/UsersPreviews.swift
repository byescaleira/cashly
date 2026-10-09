#if DEBUG
    import FeatureCore
    import FeatureUsers
    import SwiftUI

    #Preview("Novo usuário") {
        NavigationStack {
            WithSession { session, _, _ in
                ModelHost(UserEditorModel(users: session.repositories.users)) { UserEditorScreen() }
            }
        }
        .cashlyPreview()
    }
#endif
