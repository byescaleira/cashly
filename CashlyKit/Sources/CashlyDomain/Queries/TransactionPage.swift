public struct TransactionPage: Sendable {
    public let items: [Transaction]
    public let nextCursor: TransactionCursor?
    public let pendingReferences: Int

    public init(items: [Transaction], nextCursor: TransactionCursor?, pendingReferences: Int = 0) {
        self.items = items
        self.nextCursor = nextCursor
        self.pendingReferences = pendingReferences
    }
}
