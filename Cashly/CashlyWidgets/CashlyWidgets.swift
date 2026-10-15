import SwiftUI
import WidgetKit

@main
struct CashlyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MonthWidget()
        BudgetWidget()
        BudgetsWidget()
        BillsWidget()
        JourneyWidget()
        #if os(iOS)
            NewExpenseControl()
            StreakLiveActivity()
            ChallengeLiveActivity()
        #endif
    }
}
