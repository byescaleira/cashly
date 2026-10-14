import AppIntents
import SwiftUI
import WidgetKit

#if os(iOS)
    struct NewExpenseControl: ControlWidget {
        var body: some ControlWidgetConfiguration {
            StaticControlConfiguration(kind: "cashly.newExpense") {
                ControlWidgetButton(action: NewExpenseIntent()) {
                    Label("New Expense", systemImage: "plus.circle")
                }
            }
            .displayName("New Expense")
            .description("Opens Cashly on a new expense.")
        }
    }
#endif
