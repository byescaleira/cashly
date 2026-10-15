import CashlyDomain
import Foundation

public struct ReminderText: Equatable, Sendable {
    public let title: String
    public let body: String

    public static func bill(
        summary: String, amount: String, isReceiving: Bool, installment: Int, of count: Int
    ) -> ReminderText {
        let part =
            count > 1 ? String(appLocalized: " · installment \(installment) of \(count)") : ""
        return ReminderText(
            title: isReceiving
                ? String(appLocalized: "Money to receive today")
                : String(appLocalized: "Bill due today"),
            body: "\(summary) · \(amount)\(part)")
    }

    public static func budget(category: String, amount: String, isOver: Bool) -> ReminderText {
        ReminderText(
            title: isOver
                ? String(appLocalized: "\(category) is over budget")
                : String(appLocalized: "\(category) at 80% of the budget"),
            body: isOver
                ? String(appLocalized: "\(amount) over what you planned this month.")
                : String(appLocalized: "\(amount) left for the rest of the month."))
    }

    public static func weekly(spent: String, available: String?) -> ReminderText {
        ReminderText(
            title: String(appLocalized: "Your week in Cashly"),
            body: available.map {
                String(
                    appLocalized:
                        "\(spent) spent this month and \($0) still available. See what changed this week."
                )
            } ?? String(appLocalized: "\(spent) spent this month. See what changed this week."))
    }

    public static var planning: ReminderText {
        ReminderText(
            title: String(appLocalized: "Plan your month"),
            body: String(appLocalized: "Start the month by reviewing your budgets in Cashly."))
    }
}
