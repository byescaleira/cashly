import CashlyDomain
import Foundation

extension PaymentDue {
    func reminder(userID: String) -> Reminder {
        let record = transaction
        let title =
            record.status == .pendingToReceive
            ? String(appLocalized: "Money to receive today")
            : String(appLocalized: "Bill due today")
        let part =
            record.installmentCount > 1
            ? String(appLocalized: " · installment \(installment) of \(record.installmentCount)")
            : ""
        return Reminder(
            id: "payment.\(userID).\(record.id).\(month.rawValue)", title: title,
            body: "\(record.summary) · \(money.formatted)\(part)",
            components: CashlyCalendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: date),
            category: NotificationCategory.bill,
            userInfo: [NotificationCategory.transactionKey: record.id], isTimeSensitive: true)
    }
}
