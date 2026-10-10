import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct EmptyTagsSection: View {
    @Environment(\.isLoading) private var isLoading
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance

    var body: some View {
        if finance.tags.isEmpty, !finance.categories.isEmpty, session.user != nil, !isLoading {
            Section {
                MissingDataView(.tag)
            } header: {
                Text("Tags").sectionTitle()
            }
        }
    }
}
