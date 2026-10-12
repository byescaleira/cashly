import SwiftUI
import WidgetKit

@main
struct CashlyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MonthWidget()
        BudgetsWidget()
        BillsWidget()
    }
}
