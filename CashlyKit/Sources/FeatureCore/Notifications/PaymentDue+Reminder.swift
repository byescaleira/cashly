import CashlyDomain
import Foundation

extension PaymentDue {
    func reminder(userID: String) -> Reminder {
        let record = transaction
        let title =
            record.status == .pendingToReceive ? "Valor a receber hoje" : "Conta a pagar hoje"
        let part =
            record.installmentCount > 1
            ? " · parcela \(installment) de \(record.installmentCount)" : ""
        return Reminder(
            id: "payment.\(userID).\(record.id).\(month.rawValue)", title: title,
            body: "\(record.summary) · \(money.formatted)\(part)",
            components: CashlyCalendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: date))
    }
}
