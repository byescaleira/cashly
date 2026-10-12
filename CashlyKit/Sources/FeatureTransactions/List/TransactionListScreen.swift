import CashlyDesignSystem
import FeatureCore
import SwiftUI
import TipKit

public struct TransactionListScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(TransactionListModel.self) private var list

    public init() {}

    public var body: some View {
        @Bindable var list = list
        AdaptiveList(selection: $list.selection) {
            DataStatusSection()
            if !list.days.isEmpty { TipView(SwipeToDeleteTip()) }
            ForEach(list.days) { TransactionDaySection(day: $0) }
            LoadMoreSection()
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
        .toolbar { TransactionListToolbar() }
        .refreshable { await list.load() }
        .task(id: session.loadKey) { await list.load() }
        .onChange(of: session.user?.id) { list.endSelection() }
        .navigationTitle("History")
        .errorAlert($list.error)
    }
}
