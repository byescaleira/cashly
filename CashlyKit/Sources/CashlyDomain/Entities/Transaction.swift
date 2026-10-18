import Foundation

public struct Transaction: Identifiable, Hashable, Sendable {
    public var id: String
    public var ownerID: String
    public var category: Category
    public var kind: TransactionKind
    public var money: Money
    public var ownerMoney: Money?
    public var participants: [Participant]
    public var tagIDs: Set<String>
    public var date: Date
    public var summary: String
    public var status: TransactionStatus
    public var splitMode: TransactionSplitMode?
    public var splitValue: Double?
    public var paymentsPlan: Int?
    public var currencyCode: String
    public var exchange: TransactionExchange?
    public var estimate: CurrencyEstimate?

    public init(
        id: String, participants: [Participant], category: Category, money: Money, date: Date,
        summary: String, status: TransactionStatus, splitMode: TransactionSplitMode?,
        splitValue: Double?, paymentsPlan: Int?, ownerMoney: Money? = nil,
        tagIDs: Set<String> = [], kind: TransactionKind = .expense,
        currencyCode: String = Money.currencyCode, exchange: TransactionExchange? = nil,
        estimate: CurrencyEstimate? = nil
    ) {
        self.id = id
        self.ownerID = category.user.id
        self.category = category
        self.kind = kind
        self.money = money
        self.ownerMoney = ownerMoney
        self.participants = participants
        self.tagIDs = tagIDs
        self.date = date
        self.summary = summary
        self.status = status
        self.splitMode = splitMode
        self.splitValue = splitValue
        self.paymentsPlan = paymentsPlan
        self.currencyCode = currencyCode
        self.exchange = exchange
        self.estimate = estimate
    }

    public var stored: Transaction {
        guard let estimate else { return self }
        var value = self
        value.money = estimate.money
        value.ownerMoney = estimate.ownerMoney
        if !participants.isEmpty { value.splitValue = estimate.ownerMoney?.doubleValue }
        value.currencyCode = estimate.currencyCode
        value.estimate = nil
        return value
    }
}
