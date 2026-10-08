import CashlyDomain
import Foundation

public struct TransactionFilter: Equatable, Hashable {
    public var startDate: Date
    public var kinds: Set<TransactionKind>
    public var transactionStatuses: Set<TransactionStatus>
    public var categories: Set<CashlyDomain.Category>
    public var tags: Set<Tag>
    public var participants: Set<User>
    public var isFilteringByDate: Bool

    public init(
        startDate: Date = .now,
        transactionStatuses: Set<TransactionStatus> = [],
        kinds: Set<TransactionKind> = [],
        categories: Set<CashlyDomain.Category> = [],
        tags: Set<Tag> = [],
        participants: Set<User> = [],
        isFilteringByDate: Bool = true
    ) {
        self.startDate = startDate
        self.transactionStatuses = transactionStatuses
        self.kinds = kinds
        self.categories = categories
        self.tags = tags
        self.participants = participants
        self.isFilteringByDate = isFilteringByDate
    }

    public var month: YearMonth? { isFilteringByDate ? YearMonth(startDate) : nil }

    public var query: TransactionQuery {
        TransactionQuery(
            month: month, categoryIDs: Set(categories.map(\.id)), tagIDs: Set(tags.map(\.id)),
            participantUserIDs: Set(participants.map(\.id)), statuses: transactionStatuses,
            kinds: kinds)
    }

    public var keepingPeriod: TransactionFilter {
        TransactionFilter(startDate: startDate, isFilteringByDate: isFilteringByDate)
    }
}
