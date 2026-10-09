import Foundation

public struct PaymentDue: Hashable, Sendable {
    public let transaction: Transaction
    public let month: YearMonth
    public let date: Date
    public let money: Money

    public var installment: Int { month.months(since: transaction.billingStart) + 1 }
}

public enum PaymentSchedule {
    public static let pendingStatuses: Set<TransactionStatus> = [.pendingToPay, .pendingToReceive]

    public static func upcoming(
        _ transactions: [Transaction], after now: Date, hour: Int = 9, limit: Int = 50
    ) -> [PaymentDue] {
        let calendar = CashlyCalendar.current
        let dues = transactions.filter { pendingStatuses.contains($0.status) }.flatMap {
            transaction in
            transaction.billingMonths.compactMap { month -> PaymentDue? in
                guard let billing = transaction.billingDate(in: month),
                    let date = calendar.date(
                        bySettingHour: hour, minute: 0, second: 0,
                        of: calendar.startOfDay(for: billing)),
                    date > now
                else { return nil }
                return PaymentDue(
                    transaction: transaction, month: month, date: date,
                    money: transaction.billingMoney(in: month))
            }
        }
        return Array(
            dues.sorted { ($0.date, $0.transaction.id) < ($1.date, $1.transaction.id) }.prefix(
                limit))
    }
}
