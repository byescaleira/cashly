import CashlyDomain
import FeatureCore
import Foundation

public enum ActiveFilter: Identifiable, Hashable {
    case category(CashlyDomain.Category)
    case tag(Tag)
    case status(TransactionStatus)
    case participant(User)

    public var id: String {
        switch self {
        case .category(let category): "category-" + category.id
        case .tag(let tag): "tag-" + tag.id
        case .status(let status): "status-" + String(status.rawValue)
        case .participant(let user): "participant-" + user.id
        }
    }

    public var title: String {
        switch self {
        case .category(let category): category.name.capitalized
        case .tag(let tag): tag.name.capitalized
        case .status(let status): status.summary
        case .participant(let user): user.name
        }
    }

    static func all(in filter: TransactionFilter) -> [ActiveFilter] {
        let byName: (String, String) -> Bool = {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
        return filter.categories.sorted { byName($0.name, $1.name) }.map(ActiveFilter.category)
            + filter.tags.sorted { byName($0.name, $1.name) }.map(ActiveFilter.tag)
            + TransactionStatus.allCases.filter(filter.transactionStatuses.contains)
            .map(ActiveFilter.status)
            + filter.participants.sorted { byName($0.name, $1.name) }.map(ActiveFilter.participant)
    }
}
