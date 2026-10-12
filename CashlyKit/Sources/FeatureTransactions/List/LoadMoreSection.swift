import FeatureCore
import SwiftUI

struct LoadMoreSection: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(TransactionListModel.self) private var list

    var body: some View {
        if list.hasMore || list.isLoadingMore {
            Section {
                if list.hasMore {
                    Button("Load More Transactions") { Task { await list.loadMore() } }
                        .disabled(finance.isLoading || list.isLoadingMore)
                }
                if list.isLoadingMore { ProgressView() }
            }
        }
    }
}
