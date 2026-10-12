import AppIntents
import SwiftUI
import WidgetKit

#if os(iOS)
    struct NewExpenseControl: ControlWidget {
        var body: some ControlWidgetConfiguration {
            StaticControlConfiguration(kind: "cashly.newExpense") {
                ControlWidgetButton(action: NewExpenseControlIntent()) {
                    Label("New Expense", systemImage: "plus.circle")
                }
            }
            .displayName("New Expense")
            .description("Opens Cashly on a new expense.")
        }
    }

    struct NewExpenseControlIntent: AppIntent {
        static let title: LocalizedStringResource = "New Expense"
        static let openAppWhenRun = true

        func perform() async throws -> some IntentResult & OpensIntent {
            .result(opensIntent: OpenURLIntent(URL(string: "cashly://transactions/new")!))
        }
    }
#endif
