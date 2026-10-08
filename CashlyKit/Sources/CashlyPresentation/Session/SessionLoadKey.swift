import CashlyDomain

public struct SessionLoadKey: Hashable, Sendable {
    public let userID: String?
    public let query: TransactionQuery
    public let generation: Int
}
