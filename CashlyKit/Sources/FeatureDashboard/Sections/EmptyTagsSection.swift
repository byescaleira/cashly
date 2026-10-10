import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct EmptyTagsSection: View {
    @Environment(\.isLoading) private var isLoading
    @Environment(FinanceModel.self) private var finance

    var body: some View {
        if finance.tags.isEmpty, !isLoading {
            Section {
                MissingDataView(.tag)
            } header: {
                Text("Tags").sectionTitle()
            }
        }
    }
}
