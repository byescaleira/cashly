public struct TransactionQuery: Hashable, Sendable {
    public var month: YearMonth?
    public var categoryIDs: Set<String>
    public var tagIDs: Set<String>
    public var participantUserIDs: Set<String>
    public var statuses: Set<TransactionStatus>
    public var kinds: Set<TransactionKind>

    public init(
        month: YearMonth? = nil, categoryIDs: Set<String> = [], tagIDs: Set<String> = [],
        participantUserIDs: Set<String> = [], statuses: Set<TransactionStatus> = [],
        kinds: Set<TransactionKind> = []
    ) {
        self.month = month
        self.categoryIDs = categoryIDs
        self.tagIDs = tagIDs
        self.participantUserIDs = participantUserIDs
        self.statuses = statuses
        self.kinds = kinds
    }
}
