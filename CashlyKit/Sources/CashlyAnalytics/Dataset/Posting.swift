import CashlyDomain
import Foundation

public struct Posting: Hashable, Sendable {
    public let transactionID: String
    public let month: YearMonth
    public let date: Date
    public let categoryID: String
    public let summary: String
    public let tagIDs: Set<String>
    public let kind: TransactionKind
    public let status: TransactionStatus
    public let minorUnits: Int64
    public let installment: Int
    public let installments: Int

    public var signedMinorUnits: Int64 { kind == .income ? minorUnits : -minorUnits }
    public var isExpense: Bool { kind == .expense }
    public var isPending: Bool { status == .pendingToPay || status == .pendingToReceive }
}

extension Transaction {
    public var postings: [Posting] {
        guard status != .canceled else { return [] }
        return billingMonths.enumerated().compactMap { offset, month in
            let money = billingMoney(in: month)
            guard money.minorUnits != 0, let date = billingDate(in: month) else { return nil }
            return Posting(
                transactionID: id, month: month, date: date, categoryID: category.id,
                summary: summary, tagIDs: tagIDs,
                kind: kind, status: status, minorUnits: money.minorUnits, installment: offset + 1,
                installments: installmentCount)
        }
    }
}
