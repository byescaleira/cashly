#if DEBUG
    import FeatureCore
    import FeatureDashboard
    import SwiftUI

    #Preview("Início") {
        NavigationStack {
            WithSession { session, finance, intelligence in
                ModelHost(
                    DashboardModel(session: session, finance: finance, intelligence: intelligence)
                ) {
                    HomeScreen()
                }
            }
        }
        .cashlyPreview()
    }
#endif
