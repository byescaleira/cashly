import CashlyDomain
import Foundation
import Testing

struct PaymentScheduleTests {
    private let owner = User(id: "owner", name: "Perfil")

    private func transaction(
        _ id: String, cents: Int64, date: Date, plan: Int? = nil,
        status: TransactionStatus = .pendingToPay
    ) -> Transaction {
        let category = Category(id: "c", user: owner, name: "Geral", color: "0099FF", icon: "cart")
        return Transaction(
            id: id, participants: [], category: category, money: Money(minorUnits: cents),
            date: date, summary: "Conta " + id, status: status, splitMode: nil, splitValue: nil,
            paymentsPlan: plan)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(
            CashlyCalendar.current.date(from: DateComponents(year: year, month: month, day: day)))
    }

    @Test func onlyFuturePendingInstallmentsAreScheduledAtNine() throws {
        let now = try date(2026, 2, 10)
        let items = [
            transaction("plan", cents: 300, date: try date(2026, 1, 15), plan: 3),
            transaction("done", cents: 100, date: try date(2026, 3, 1), status: .settled),
            transaction("later", cents: 50, date: try date(2026, 2, 12), status: .pendingToReceive),
        ]
        let dues = PaymentSchedule.upcoming(items, after: now)
        #expect(dues.map(\.transaction.id) == ["later", "plan", "plan"])
        #expect(dues.map(\.installment) == [1, 2, 3])
        #expect(dues[1].money == Money(minorUnits: 100))
        let hour = CashlyCalendar.current.component(.hour, from: dues[0].date)
        #expect(hour == 9)
    }

    @Test func limitKeepsTheNearest() throws {
        let now = try date(2026, 1, 1)
        let items = (1...5).map { day in
            transaction("t\(day)", cents: 10, date: (try? date(2026, 1, 10 - day)) ?? now)
        }
        let dues = PaymentSchedule.upcoming(items, after: now, limit: 2)
        #expect(dues.map(\.transaction.id) == ["t5", "t4"])
    }
}
