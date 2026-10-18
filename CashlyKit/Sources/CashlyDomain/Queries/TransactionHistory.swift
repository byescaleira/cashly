public struct TransactionHistory: Sendable {
    public let transactions: [Transaction]
    public let tags: [Tag]
    public let revision: String

    public init(transactions: [Transaction], tags: [Tag], revision: String) {
        self.transactions = transactions
        self.tags = tags
        self.revision = revision
    }
}
