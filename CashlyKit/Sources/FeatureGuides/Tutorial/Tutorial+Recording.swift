import FeatureCore

extension Guide {
    static var tourPages: [TutorialPage] {
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
    }

    static var recordingPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .history, title: "Tap Plus",
                message:
                    "In History, tap +. The amount comes first, big and ready to type, so a coffee takes three taps."
            ),
            TutorialPage(
                animation: .editor, title: "Category and Description",
                message:
                    "Pick a category and add a short description. Mark it paid or pending, and change the date if it wasn't today."
            ),
            TutorialPage(
                animation: .tags, title: "Tags and Installments",
                message:
                    "Tags cut across categories: Trip, Home, Work. Paying in installments? Set how many and Cashly spreads them over the months."
            ),
        ]
    }

    static var sharingPages: [TutorialPage] {
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
                animation: .paid, title: "Who Paid",
                message:
                    "Choose who paid, then mark each share as paid or to receive. History shows what is still owed."
            ),
        ]
    }

    static var billsPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .bills, title: "Record Before You Pay",
                message:
                    "Save a bill as pending with its due date. It counts in the plan from day one, and the Upcoming Bills widget keeps the next ones in sight."
            ),
            TutorialPage(
                animation: .capture, title: "A Reminder at 9 AM",
                message:
                    "On the due day, a notification arrives at 9 AM with Mark as Paid and Postpone. Turn it on in Settings › Notifications."
            ),
            TutorialPage(
                animation: .paid, title: "Mark as Paid",
                message:
                    "Mark it from the notification, from the transaction, or say \"Mark a bill as paid in Cashly\" to Siri."
            ),
        ]
    }
}
