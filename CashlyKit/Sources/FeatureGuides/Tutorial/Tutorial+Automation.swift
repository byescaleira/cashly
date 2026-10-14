import FeatureCore

extension Guide {
    static var widgetsPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .widgets, title: "Four Widgets",
                message:
                    "This Month shows spent, planned and what is left. Budgets lists every bar. Upcoming Bills shows what is due. One Budget follows the category you pick in Settings › Widgets."
            ),
            TutorialPage(
                animation: .month, title: "Lock Screen",
                message:
                    "This Month also fits the Lock Screen, so a glance tells you where you stand. Widgets refresh every hour and whenever you open Cashly."
            ),
            TutorialPage(
                animation: .launch, title: "One Tap to a New Expense",
                message:
                    "Add the New Expense control to Control Center or to the Action Button. It opens Cashly straight on a new expense."
            ),
        ]
    }

    static var siriPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .siri, title: "Ask Siri",
                message:
                    "Say \"Add an expense in Cashly\" or \"How much did I spend this month in Cashly\". Siri answers without opening the app."
            ),
            TutorialPage(
                animation: .budget, title: "More Phrases",
                message:
                    "\"How much is left in Groceries in Cashly\", \"Mark a bill as paid in Cashly\" and \"Capture a payment in Cashly\"."
            ),
            TutorialPage(
                animation: .capture, title: "In Shortcuts",
                message:
                    "The same actions appear in the Shortcuts app and in Spotlight. Chain them: a shortcut that records your commute every weekday."
            ),
        ]
    }

    static var capturePages: [TutorialPage] {
        [
            TutorialPage(
                animation: .capture, title: "Pay, and Cashly Knows",
                message:
                    "In Shortcuts, create an automation with the Transaction trigger, set to run immediately. Choose Capture a Payment in Cashly and pass the amount, merchant, card and date."
            ),
            TutorialPage(
                animation: .bills, title: "Confirm from the Notification",
                message:
                    "Each payment arrives as a notification with a suggested category. Tap to confirm, pick another, or ignore. The app icon counts what is waiting."
            ),
            TutorialPage(
                animation: .done, title: "It Learns Your Places",
                message:
                    "Accept a suggestion once and the next payment at that merchant arrives ready. Capturing never needs Cashly Pro; turning it into a transaction does, like any edit."
            ),
        ]
    }
}
