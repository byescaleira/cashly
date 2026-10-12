import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct TransactionListScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(TransactionListModel.self) private var list

    public init() {}

    public var body: some View {
        @Bindable var list = list
        List(selection: $list.selection) {
            TransactionBalanceSection()
            DataStatusSection()
            ForEach(list.days) { TransactionDaySection(day: $0) }
            LoadMoreRow()
        }
        #if os(iOS) || os(visionOS)
            .environment(
                \.editMode,
                Binding(
                    get: { list.isSelecting ? .active : .inactive },
                    set: { list.isSelecting = $0 == .active }))
        #endif
        .emptyState(.transaction, when: list.days.isEmpty && !list.isLoading)
        .fontDesign(.rounded)
        .readableWidth()
        .toolbar { TransactionListToolbar() }
        .refreshable { await list.load() }
        .task(id: session.loadKey) { await list.load() }
        .onChange(of: session.user?.id) { list.endSelection() }
        .navigationTitle("Histórico")
        .errorAlert($list.error)
    }
}
