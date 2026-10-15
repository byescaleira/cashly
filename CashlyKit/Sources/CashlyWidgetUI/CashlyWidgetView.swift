import CashlyDomain
import SwiftUI

public struct CashlyWidgetView: View {
    private let widget: CashlyWidget
    private let size: WidgetSize
    private let snapshot: WidgetSnapshot?

    public init(_ widget: CashlyWidget, size: WidgetSize, snapshot: WidgetSnapshot?) {
        self.widget = widget
        self.size = size
        self.snapshot = snapshot
    }

    public var body: some View {
        switch widget {
        case .month: MonthWidgetView(snapshot: snapshot, size: size, isFocused: false)
        case .budget: MonthWidgetView(snapshot: snapshot, size: size, isFocused: true)
        case .budgets: BudgetsWidgetView(snapshot: snapshot, size: size)
        case .bills: BillsWidgetView(snapshot: snapshot, size: size)
        }
    }
}
