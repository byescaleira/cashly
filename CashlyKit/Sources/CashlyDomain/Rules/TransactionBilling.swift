import Foundation

extension Transaction {
    public var billingStart: YearMonth { YearMonth(date) }

    public var installmentCount: Int { max(paymentsPlan ?? 1, 1) }

    public var billingMonths: [YearMonth] {
        (0..<min(installmentCount, 1200)).map { billingStart.adding(months: $0) }
    }

    public func occurs(in month: YearMonth) -> Bool {
        guard let paymentsPlan else { return billingStart == month }
        guard (1...1200).contains(paymentsPlan) else { return false }
        let offset = month.months(since: billingStart)
        return offset >= 0 && offset < paymentsPlan
    }

    public func billingDate(in month: YearMonth) -> Date? {
        guard occurs(in: month) else { return nil }
        let calendar = CashlyCalendar.current
        var components = calendar.dateComponents([.day, .hour, .minute, .second], from: date)
        components.year = month.year
        components.month = month.month
        components.day = min(components.day ?? 1, month.dayCount)
        return calendar.date(from: components)
    }

    public var attributedMoney: Money {
        guard status != .canceled else { return .zero }
        return ownerMoney
            ?? (try? TransactionAllocation.resolve(total: money, participants: participants).owner)
            ?? .zero
    }

    public func billingMoney(in month: YearMonth?) -> Money {
        installment(of: attributedMoney, in: month)
    }

    public func participantMoney(id: String, in month: YearMonth? = nil) -> Money {
        guard status != .canceled, let participant = participants.first(where: { $0.id == id })
        else { return .zero }
        let value =
            participant.allocatedMoney
            ?? (try? TransactionAllocation.resolve(total: money, participants: participants))?
            .participants[id]
            ?? .zero
        return installment(of: value, in: month)
    }

    private func installment(of value: Money, in month: YearMonth?) -> Money {
        guard let month else { return value }
        guard occurs(in: month) else { return .zero }
        return value.installment(at: month.months(since: billingStart), count: installmentCount)
    }
}
