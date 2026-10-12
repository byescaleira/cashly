import CashlyDomain
import Foundation

public enum TransactionShareMessage {
    public static func make(
        transactions: Set<Transaction>, participants: Set<User>, month: YearMonth? = nil
    ) -> String {
        let ids = Set(participants.map(\.id))
        let records = transactions.filter { ids.isEmpty || $0.kind == .expense }
            .sorted { $0.date < $1.date }
        func share(_ transaction: Transaction) throws -> Money {
            guard !ids.isEmpty else { return transaction.billingMoney(in: month) }
            return try transaction.participants.filter { ids.contains($0.user.id) }.reduce(.zero) {
                try $0.adding(transaction.participantMoney(id: $1.id, in: month))
            }
        }
        do {
            let expenses = try records.filter { $0.kind == .expense }.reduce(Money.zero) {
                try $0.adding(share($1))
            }
            let income = try records.filter { $0.kind == .income }.reduce(Money.zero) {
                try $0.adding(share($1))
            }
            let net = try income.subtracting(expenses)
            let lines = try records.map { transaction in
                let date = (month.flatMap { transaction.billingDate(in: $0) } ?? transaction.date)
                    .formatted(.dateTime.day().month(.wide).year().hour().minute().locale(.app))
                return
                    " \(transaction.kind.title): \(try share(transaction).formatted)\n 🗓 \(date)\n 🏷️ \(transaction.category.name.capitalized) - \(transaction.summary)\n"
            }.joined(separator: "\n")
            let totals = [
                String(appLocalized: "📊 Records: \(records.count)"),
                String(appLocalized: "Money in: \(income.formatted)"),
                String(appLocalized: "Money out: \(expenses.formatted)"),
                String(appLocalized: "Balance: \(net.formatted)"),
            ]
            return String(appLocalized: "💸 Financial summary") + "\n\n" + lines + "\n"
                + totals.joined(separator: "\n")
        } catch {
            return String(
                appLocalized:
                    "Couldn't create the summary: the total exceeds the allowed amount range.")
        }
    }
}
