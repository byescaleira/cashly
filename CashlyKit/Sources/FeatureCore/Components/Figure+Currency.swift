import CashlyDesignSystem
import SwiftUI

extension FigureHeader {
    public init(
        title: LocalizedStringKey, amount: Double, color: Color = .primary,
        @ViewBuilder detail: () -> Detail = { EmptyView() }
    ) {
        self.init(
            title: title, value: amount.formatted(.appCurrency), numeric: amount, color: color,
            detail: detail)
    }
}

extension FigureBlock {
    public init(caption: String, amount: Double, color: Color = .primary, detail: String? = nil) {
        self.init(
            caption: caption, value: amount.formatted(.appCurrency), numeric: amount, color: color,
            detail: detail)
    }
}
