import FeatureCore
import SwiftUI

struct LoadMoreRow: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(TransactionListModel.self) private var list

    var body: some View {
        if list.hasMore {
            Button("Carregar mais transações") { Task { await list.loadMore() } }
                .disabled(finance.isLoading || list.isLoadingMore)
        }
        if list.isLoadingMore { ProgressView() }
    }
}
