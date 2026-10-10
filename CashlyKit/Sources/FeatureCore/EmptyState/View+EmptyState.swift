import CashlyDesignSystem
import SwiftUI

extension View {
    @ViewBuilder public func emptyState(_ prerequisite: Prerequisite, when isEmpty: Bool)
        -> some View
    {
        if isEmpty {
            MissingDataView(prerequisite)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.groupedBackground)
        } else {
            self
        }
    }
}
