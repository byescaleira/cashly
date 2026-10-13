import SwiftUI
import WidgetKit

@main
struct CashlyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MonthWidget()
        BudgetWidget()
        BudgetsWidget()
        BillsWidget()
        #if os(iOS)
            NewExpenseControl()
        #endif
    }
}
