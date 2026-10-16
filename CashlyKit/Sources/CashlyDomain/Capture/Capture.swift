import Foundation

public struct Capture: Identifiable, Hashable, Sendable {
    public enum Source: String, Sendable {
        case wallet, share, manual
    }

    public enum Status: String, Sendable {
        case pending, accepted, dismissed
    }

    public var id: String
    public var ownerID: String
    public var money: Money
    public var merchant: String
    public var card: String
    public var date: Date
    public var source: Source
    public var suggestedCategoryID: String?
    public var suggestedSummary: String
    public var suggestedTagIDs: Set<String>
    public var status: Status
    public var transactionID: String?
    public var createdAt: Date
    public var currencyCode = Money.currencyCode

    public init(
        id: String = UUID().uuidString, ownerID: String, money: Money, merchant: String,
        card: String = "", date: Date, source: Source, suggestedCategoryID: String? = nil,
        suggestedSummary: String = "", suggestedTagIDs: Set<String> = [],
        status: Status = .pending, transactionID: String? = nil, createdAt: Date = .now
    ) {
        self.id = id
        self.ownerID = ownerID
        self.money = money
        self.merchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        self.card = card.trimmingCharacters(in: .whitespacesAndNewlines)
        self.date = date
        self.source = source
        self.suggestedCategoryID = suggestedCategoryID
        self.suggestedSummary = suggestedSummary
        self.suggestedTagIDs = suggestedTagIDs
        self.status = status
        self.transactionID = transactionID
        self.createdAt = createdAt
    }

    public var merchantKey: String { MerchantMemory.key(for: merchant) }

    public var minute: Int64 { Int64((date.timeIntervalSince1970 / 60).rounded(.down)) }

    public func isDuplicate(of other: Capture) -> Bool {
        ownerID == other.ownerID && money == other.money && merchantKey == other.merchantKey
            && minute == other.minute
    }
}
