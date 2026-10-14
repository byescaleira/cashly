import AppIntents
import SwiftUI
import WidgetKit

#if os(iOS)
    struct NewExpenseControl: ControlWidget {
        var body: some ControlWidgetConfiguration {
            StaticControlConfiguration(kind: "cashly.newExpense") {
                ControlWidgetButton(action: OpenURLIntent(.newExpense)) {
                    Label("New Expense", systemImage: "plus.circle")
                }
            }
            .displayName("New Expense")
            .description("Opens Cashly on a new expense.")
        }
    }

    extension URL {
        fileprivate static let newExpense = URL(string: "cashly://transactions/new")!
    }
#endif
