#if DEBUG
    import FeatureCore
    import FeatureReports
    import SwiftUI

    #Preview("Relatórios") {
        NavigationStack {
            WithSession { session, finance, intelligence in
                ModelHost(
                    ReportsModel(session: session, finance: finance, intelligence: intelligence)
                ) {
                    ReportsScreen()
                }
            }
        }
        .cashlyPreview()
    }
#endif
