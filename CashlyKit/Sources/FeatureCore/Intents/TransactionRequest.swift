import CashlyDomain
import Foundation

public struct TransactionRequest: Equatable, Sendable {
    public enum Status: Equatable, Sendable {
        case paid
        case pending
    }

    public var kind: TransactionKind
    public var amount: Double
    public var categoryID: String
    public var summary: String
    public var date: Date?
    public var status: Status
    public var tagIDs: Set<String>
    public var participantIDs: [String]
    public var splitMode: TransactionSplitMode
    public var share: Double?
    public var installments: Int?

    public init(
        kind: TransactionKind = .expense, amount: Double, categoryID: String, summary: String = "",
        date: Date? = nil, status: Status = .paid, tagIDs: Set<String> = [],
        participantIDs: [String] = [], splitMode: TransactionSplitMode = .equal,
        share: Double? = nil, installments: Int? = nil
    ) {
        self.kind = kind
        self.amount = amount
        self.categoryID = categoryID
        self.summary = summary
        self.date = date
        self.status = status
        self.tagIDs = tagIDs
        self.participantIDs = participantIDs
        self.splitMode = splitMode
        self.share = share
        self.installments = installments
    }

    public var transactionStatus: TransactionStatus {
        switch status {
        case .paid: .settled
        case .pending: kind == .income ? .pendingToReceive : .pendingToPay
        }
    }

    public var needsShare: Bool {
        !participantIDs.isEmpty && splitMode != .equal && share == nil
    }
}
