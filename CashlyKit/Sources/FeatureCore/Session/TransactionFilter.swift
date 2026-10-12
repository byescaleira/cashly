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

    public var monthNumber: Int {
        get { YearMonth(startDate).month }
        set { move(year: year, month: newValue) }
    }

    public var year: Int {
        get { YearMonth(startDate).year }
        set { move(year: newValue, month: monthNumber) }
    }

    public var periodTitle: String {
        isFilteringByDate
            ? startDate.formatted(.dateTime.month(.wide).year().locale(.app))
            : String(appLocalized: "All data")
    }

    public var isCurrentMonth: Bool { YearMonth(startDate) == YearMonth(.now) }

    public var isCustomized: Bool {
        !isFilteringByDate || !isCurrentMonth || !categories.isEmpty || !tags.isEmpty
            || !transactionStatuses.isEmpty || !participants.isEmpty
    }

    public static var selectableYears: ClosedRange<Int> {
        let current = YearMonth(.now).year
        return (current - 5)...(current + 5)
    }

    public mutating func reset() {
        self = TransactionFilter(kinds: kinds)
    }

    private mutating func move(year: Int, month: Int) {
        if let value = YearMonth(year: year, month: month) { startDate = value.startDate }
    }

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
