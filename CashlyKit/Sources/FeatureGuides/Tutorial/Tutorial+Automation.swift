import CashlyDesignSystem
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
                    "Say \"Add an expense in Cashly\": Siri asks the amount and the category, then saves it. \"How much did I spend this month in Cashly\" answers without opening the app."
            ),
            TutorialPage(
                animation: .budget, title: "More Phrases",
                message:
                    "\"Add income in Cashly\", \"How much is left in Groceries in Cashly\", \"Mark a bill as paid in Cashly\" and \"Capture a payment in Cashly\"."
            ),
            TutorialPage(
                animation: .capture, title: "In Shortcuts",
                message:
                    "In the Shortcuts app, Add Expense has every field of the editor: description, status, date, tags, participants, split, installments and profile. Chain them: a shortcut that records your commute every weekday."
            ),
        ]
    }

    static var capturePages: [TutorialPage] {
        [
            TutorialPage(
                animation: .capture, title: "Set Up Once, Then Forget It",
                message: "A Shortcuts automation sends every Apple Pay purchase to Cashly.",
                steps: [
                    GuideStep(
                        "wallet.pass.fill", color: .retroDenim, title: "You pay with Apple Pay",
                        detail: "Any card in Wallet, on iPhone or Apple Watch."),
                    GuideStep(
                        "tray.and.arrow.down.fill", color: .retroOrange,
                        title: "Cashly captures it",
                        detail: "Amount, merchant and card, with a suggested category."),
                    GuideStep(
                        "checkmark.circle.fill", color: .retroOlive, title: "You confirm",
                        detail: "One tap on the notification turns it into a transaction."),
                ]
            ),
            TutorialPage(
                animation: .capture, title: "Create the Automation",
                message: "iOS lets only you create automations, so this part takes a minute.",
                steps: [
                    GuideStep(
                        "square.stack.3d.up.fill", color: .retroTeal,
                        title: "Shortcuts › Automation",
                        detail: "Tap + and choose Transaction."),
                    GuideStep(
                        "creditcard.fill", color: .retroDenim, title: "Pick your cards",
                        detail: "Leave every category on, then choose Run Immediately."),
                    GuideStep(
                        "plus.circle.fill", color: .retroOrange, title: "Create New Shortcut",
                        detail: "Tap Next, then start a new blank shortcut."),
                ],
                link: .shortcuts
            ),
            TutorialPage(
                animation: .editor, title: "Add the Cashly Action",
                message: "Search for Cashly and connect what the purchase already knows.",
                steps: [
                    GuideStep(
                        "magnifyingglass", color: .retroTeal, title: "Capture Payment",
                        detail: "Search Cashly in the actions and add Capture Payment."),
                    GuideStep(
                        "arrow.right.circle.fill", color: .retroOrange,
                        title: "Amount and Merchant",
                        detail: "Tap each field and pick Shortcut Input › Amount and › Merchant."),
                    GuideStep(
                        "checkmark.seal.fill", color: .retroOlive, title: "Done",
                        detail: "Your next Apple Pay purchase arrives in Cashly."),
                ],
                link: .shortcuts
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

    static var backTapPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .editor, title: "Two Taps, a New Expense",
                message: "Tap the back of your iPhone twice and Cashly asks what you spent.",
                steps: [
                    GuideStep(
                        "hand.tap.fill", color: .retroOrange, title: "Double-tap the back",
                        detail: "Works on any screen, even inside other apps."),
                    GuideStep(
                        "text.bubble.fill", color: .retroTeal, title: "Answer two questions",
                        detail: "Amount and category. Show More adds the rest of the editor."),
                    GuideStep(
                        "checkmark.circle.fill", color: .retroOlive, title: "Saved",
                        detail: "It lands in History like any other expense."),
                ]
            ),
            TutorialPage(
                animation: .editor, title: "Turn On Back Tap",
                message: "Back Tap lives in the Accessibility settings of your iPhone.",
                steps: [
                    GuideStep(
                        "gearshape.fill", color: .retroDenim, title: "Settings › Accessibility",
                        detail: "Then Touch › Back Tap."),
                    GuideStep(
                        "hand.tap.fill", color: .retroOrange, title: "Double Tap",
                        detail: "Scroll down to the Shortcuts section."),
                    GuideStep(
                        "plus.circle.fill", color: .retroOlive, title: "Add Expense",
                        detail: "Choose Add Expense from Cashly. Triple Tap can hold Add Income."),
                ]
            ),
            TutorialPage(
                animation: .launch, title: "Prefer a Button?",
                message:
                    "The New Expense control opens Cashly on a new expense from Control Center, the Lock Screen or the Action Button."
            ),
        ]
    }
}
