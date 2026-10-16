import CashlyDomain
import SwiftUI

public struct FilterMenu: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(\.appTint) private var appTint

    public init() {}

    public var body: some View {
        @Bindable var session = session
        if session.user != nil, !finance.allCategories.isEmpty {
            Menu {
                DateFilterMenu(filter: $session.filter)
                Divider()
                if !finance.allCategories.isEmpty {
                    MultiSelectMenu(
                        "Categories", systemImage: "swatchpalette", items: finance.allCategories,
                        selection: $session.filter.categories
                    ) { Text($0.name.capitalized) }
                }
                if !finance.allTags.isEmpty {
                    MultiSelectMenu(
                        "Tags", systemImage: "tag", items: finance.allTags,
                        selection: $session.filter.tags
                    ) { Text($0.name.capitalized) }
                }
                if finance.hasTransactions {
                    MultiSelectMenu(
                        "Status", systemImage: "text.pad.header.badge.clock",
                        items: finance.allStatuses, selection: $session.filter.transactionStatuses
                    ) { Text($0.summary) }
                }
                if !session.users.isEmpty, finance.hasTransactions {
                    MultiSelectMenu(
                        "Shared with", systemImage: "person.2", items: session.users,
                        selection: $session.filter.participants
                    ) { Text($0.name) }
                }
                if session.filter.isCustomized {
                    Divider()
                    Button("Clear Filters", systemImage: "eraser.line.dashed") {
                        session.filter.reset()
                    }
                }
            } label: {
                Label("Filters", systemImage: "line.3.horizontal.decrease")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(session.filter.isCustomized ? appTint : Color.primary)
                    .symbolEffect(.bounce, value: session.filter.isCustomized)
                    .accessibilityValue(session.filter.isCustomized ? Text("On") : Text("Off"))
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .tint(Color.primary)
        }
    }
}

private struct DateFilterMenu: View {
    @Binding var filter: TransactionFilter

    var body: some View {
        Menu {
            Toggle("Filter by Date", isOn: $filter.isFilteringByDate)
            if filter.isFilteringByDate {
                Divider()
                Menu {
                    Picker(selection: $filter.monthNumber) {
                        ForEach(
                            Array(CashlyCalendar.current.monthSymbols.enumerated()), id: \.offset
                        ) {
                            Text($0.element.capitalized).tag($0.offset + 1)
                        }
                    } label: {
                        EmptyView()
                    }
                } label: {
                    Text(
                        filter.startDate.formatted(.dateTime.month(.wide).locale(.app)).capitalized)
                }
                Menu {
                    Picker(selection: $filter.year) {
                        ForEach(TransactionFilter.selectableYears, id: \.self) {
                            Text(String($0)).tag($0)
                        }
                    } label: {
                        EmptyView()
                    }
                } label: {
                    Text(filter.startDate.formatted(.dateTime.year().locale(.app)))
                }
                if !filter.isCurrentMonth {
                    Divider()
                    Button("Today", systemImage: "location") { filter.startDate = .now }
                }
            }
        } label: {
            Label("Date", systemImage: "calendar")
        }
    }
}
