#if DEBUG
    import FeatureCore
    import FeatureDashboard
    import SwiftUI

    #Preview("Início") {
        NavigationStack {
            WithSession { session, finance, _ in
                ModelHost(DashboardModel(session: session, finance: finance)) {
                    ModelHost(
                        ReportsModel(finance: finance)
                    ) {
                        ModelHost(InsightsModel(session: session, finance: finance)) {
                            HomeScreen()
                        }
                    }
                }
            }
        }
        .cashlyPreview()
    }
#endif
