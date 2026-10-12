import FeatureCore
import SwiftUI

struct TutorialPage: Identifiable {
    let id = UUID()
    let animation: CashlyAnimation
    let title: LocalizedStringKey
    let message: LocalizedStringKey
}

extension Guide {
    var pages: [TutorialPage] {
        switch self {
        case .tour:
            [
                TutorialPage(
                    animation: .month, title: "Home",
                    message:
                        "The month at a glance: money in, money out, your score and how much you can still spend."
                ),
                TutorialPage(
                    animation: .history, title: "History",
                    message:
                        "All money in and out, by day. Tap + to add a transaction and swipe to edit."
                ),
                TutorialPage(
                    animation: .budgetPace, title: "Goals",
                    message:
                        "Budgets and categories. Set how much you want to spend and follow the month's pace."
                ),
                TutorialPage(
                    animation: .journey, title: "Journey",
                    message:
                        "Levels, a streak, weekly missions and challenges that reward following your money, never spending more."
                ),
            ]
        case .budgets:
            [
                TutorialPage(
                    animation: .budget,
                    title: "One Budget per Category",
                    message:
                        "In Goals, tap + and choose the category, month and amount."
                ),
                TutorialPage(
                    animation: .budgetPace,
                    title: "Follow the Pace",
                    message:
                        "The bars show usage: green on track, mustard close to the limit, rust over plan."
                ),
                TutorialPage(
                    animation: .score, title: "Health Score",
                    message:
                        "On Home, the score goes from 200 to 1,000 and rises when spending stays within plan."
                ),
            ]
        case .sharing:
            [
                TutorialPage(
                    animation: .participants, title: "Participants",
                    message: "In a transaction, add the people who split the bill with you."),
                TutorialPage(
                    animation: .splitModes, title: "How to Split",
                    message:
                        "Equally, by fixed amount or by percentage. Cashly works out each person's share."
                ),
                TutorialPage(
                    animation: .paid, title: "Who Already Paid",
                    message:
                        "Mark each participant as paid or to receive to know who still owes."
                ),
            ]
        case .quickCapture:
            [
                TutorialPage(
                    animation: .capture, title: "Ask Siri",
                    message:
                        "Say \"Add an expense in Cashly\" or \"How much did I spend this month in Cashly\". The same shortcuts appear in the Shortcuts app and in Spotlight."
                ),
                TutorialPage(
                    animation: .paid, title: "Pay, and It's Recorded",
                    message:
                        "In Shortcuts, create an automation with the Transaction trigger: when you pay with Apple Pay, run Add Expense in Cashly with the amount and the merchant."
                ),
                TutorialPage(
                    animation: .launch, title: "One Tap Away",
                    message:
                        "Add the New Expense control to Control Center or to the Action Button, and put the widgets on your Home Screen."
                ),
            ]
        case .importSpreadsheet, .score: []
        }
    }
}
