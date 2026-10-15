import CashlyDomain
import Foundation

extension PaymentDue {
    func reminder(userID: String) -> Reminder {
        let record = transaction
        let text = ReminderText.bill(
            summary: record.summary, amount: money.formatted,
            isReceiving: record.status == .pendingToReceive, installment: installment,
            of: record.installmentCount)
        return Reminder(
            id: "payment.\(userID).\(record.id).\(month.rawValue)", title: text.title,
            body: text.body,
            components: CashlyCalendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: date),
            category: NotificationCategory.bill,
            userInfo: [NotificationCategory.transactionKey: record.id], isTimeSensitive: true)
    }
}
