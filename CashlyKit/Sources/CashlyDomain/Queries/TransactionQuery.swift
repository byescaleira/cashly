import Foundation

public struct TransactionQuery: Hashable, Sendable {
    public var month: YearMonth?
    public var categoryIDs: Set<String>
    public var tagIDs: Set<String>
    public var participantUserIDs: Set<String>
    public var statuses: Set<TransactionStatus>
    public var kinds: Set<TransactionKind>
    public var text: String

    public init(
        month: YearMonth? = nil, categoryIDs: Set<String> = [], tagIDs: Set<String> = [],
        participantUserIDs: Set<String> = [], statuses: Set<TransactionStatus> = [],
        kinds: Set<TransactionKind> = [], text: String = ""
    ) {
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.month = month
        self.categoryIDs = categoryIDs
        self.tagIDs = tagIDs
        self.participantUserIDs = participantUserIDs
        self.statuses = statuses
        self.kinds = kinds
    }

    public func matches(text value: String) -> Bool {
        text.isEmpty || value.localizedStandardContains(text)
    }
}
