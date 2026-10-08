import CashlyDomain
import Foundation
import Testing

struct TransactionBillingTests {
    private let owner = User(id: "owner", name: "Owner", photo: "")
    private let friend = User(id: "friend", name: "Friend", photo: "")

    private func month(_ year: Int, _ month: Int) throws -> YearMonth {
        try #require(YearMonth(year: year, month: month))
    }

    private func transaction(
        cents: Int64, on date: Date, plan: Int? = nil, status: TransactionStatus = .settled,
        participants: [Participant] = []
    ) -> Transaction {
        Transaction(
            id: "t", participants: participants,
            category: Category(id: "c", user: owner, name: "Geral", color: "", icon: ""),
            money: Money(minorUnits: cents), date: date, summary: "Compra", status: status,
            splitMode: participants.isEmpty ? nil : .equal, splitValue: nil, paymentsPlan: plan)
    }

    @Test func singlePaymentOccursOnlyInItsMonth() throws {
        let january = try month(2026, 1)
        let record = transaction(cents: 1000, on: january.startDate)
        #expect(record.occurs(in: january))
        #expect(!record.occurs(in: january.adding(months: 1)))
        #expect(record.billingMoney(in: january) == Money(minorUnits: 1000))
        #expect(record.billingMoney(in: january.adding(months: 1)) == .zero)
        #expect(record.billingMoney(in: nil) == Money(minorUnits: 1000))
    }

    @Test func installmentsSpreadCentsAcrossMonths() throws {
        let november = try month(2025, 11)
        let record = transaction(cents: 10001, on: november.startDate, plan: 3)
        #expect(
            record.billingMonths == [
                november, november.adding(months: 1), november.adding(months: 2),
            ])
        let parts = record.billingMonths.map { record.billingMoney(in: $0).minorUnits }
        #expect(parts == [3334, 3334, 3333])
        #expect(!record.occurs(in: november.adding(months: 3)))
        #expect(!record.occurs(in: november.adding(months: -1)))
    }

    @Test func canceledTransactionsCountAsZero() throws {
        let january = try month(2026, 1)
        let record = transaction(cents: 1000, on: january.startDate, status: .canceled)
        #expect(record.billingMoney(in: january) == .zero)
    }

    @Test func billingDateKeepsDayAndClampsToMonthEnd() throws {
        let calendar = CashlyCalendar.current
        let date = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 10)))
        let record = transaction(cents: 300, on: date, plan: 2)
        let february = try month(2026, 2)
        let billed = try #require(record.billingDate(in: february))
        let components = calendar.dateComponents([.month, .day, .hour], from: billed)
        #expect(components.month == 2)
        #expect(components.day == 28)
        #expect(components.hour == 10)
        #expect(record.billingDate(in: february.adding(months: 1)) == nil)
    }

    @Test func ownerAndParticipantSharesReconcileTotal() throws {
        let january = try month(2026, 1)
        let share = Participant(
            id: "p", user: friend, splitMode: .equal, splitValue: 2, status: .pendingToReceive,
            transaction: "t")
        let record = transaction(cents: 1001, on: january.startDate, participants: [share])
        let ownerPart = record.billingMoney(in: january)
        let friendPart = record.participantMoney(id: "p", in: january)
        #expect(ownerPart.minorUnits + friendPart.minorUnits == 1001)
        #expect(ownerPart.minorUnits == 501)
        #expect(record.participantMoney(id: "unknown") == .zero)
    }
}
