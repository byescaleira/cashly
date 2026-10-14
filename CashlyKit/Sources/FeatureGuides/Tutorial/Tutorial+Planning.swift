import FeatureCore

extension Guide {
    static var budgetsPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .budget, title: "One Budget per Category",
                message:
                    "In Goals, tap + and choose the category, month and amount. Start with the three categories you spend most on."
            ),
            TutorialPage(
                animation: .budgetPace, title: "Follow the Pace",
                message:
                    "The bars show how much of each budget is used: green on track, mustard close to the limit, rust over plan."
            ),
            TutorialPage(
                animation: .month, title: "Alerts at 80% and 100%",
                message:
                    "With Budget Alerts on, Cashly warns you at 80% and again at 100%. On the first day of the month, a reminder asks you to plan the next one."
            ),
        ]
    }

    static var insightsPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .month, title: "You Can Spend",
                message:
                    "Home opens with how much you can still spend per day without going over plan. Installments already committed are taken out first."
            ),
            TutorialPage(
                animation: .insights, title: "Month Forecast",
                message:
                    "Cashly projects where the month will land from your pace so far and the bills you have already recorded. It updates every time you record."
            ),
            TutorialPage(
                animation: .budgetPace, title: "Out of the Ordinary",
                message:
                    "Spending that stands out against other months is flagged, with the transactions behind it. Compare months to see what changed."
            ),
        ]
    }

    static var journeyPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .journey, title: "Level Up",
                message:
                    "Recording, planning and closing the month in the green earn XP. Fifty levels, a new title every five. XP never depends on how much you spend."
            ),
            TutorialPage(
                animation: .streak, title: "Keep the Streak",
                message:
                    "A day counts when you record something or tap I Didn't Spend Today. A freeze covers a missed day; you earn one every 14 days."
            ),
            TutorialPage(
                animation: .missions, title: "Missions and Challenges",
                message:
                    "Three short missions every week, 25 XP each. Pick one challenge a month, like a week without delivery or a spending cap."
            ),
            TutorialPage(
                animation: .shopIcons, title: "The Shop",
                message:
                    "Icons, colors, streak helps and challenge packs. Items are yours for good. Every guide you finish is worth 20 XP."
            ),
        ]
    }
}
