import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import CashlyResource
import FeatureCore
import Foundation
import SwiftUI

struct FilterItemView: View {

    @Environment(SessionModel.self) var session

    @Environment(FinanceModel.self) var finance
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    var selectedMenus: Set<FilterItem>

    init(menus: [FilterItem] = FilterItem.allCases) {
        selectedMenus = Set(menus)
    }

    func contains(_ menu: FilterItem) -> Bool {
        selectedMenus.contains(menu)
    }

    @ViewBuilder
    var body: some View {
        if session.user != nil,
            !finance.allCategories.isEmpty
        {
            Menu {
                if contains(.date) {
                    toggleDateMenu
                    Divider()
                }

                if contains(.categories), !finance.allCategories.isEmpty {
                    categoriesMenu
                }

                if contains(.tags), !finance.allTags.isEmpty {
                    tagsMenu
                }

                if contains(.statuses), finance.hasTransactions {
                    statusesMenu
                }

                if contains(.participants), !session.users.isEmpty, finance.hasTransactions {
                    participantsMenu
                }

                cleanMenu
            } label: {
                CashlySymbol("line.3.horizontal.decrease")
                    .cashly(color: .text)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
        }
    }

    private var selectedMonth: Binding<Int> {
        Binding(
            get: { YearMonth(session.filter.startDate).month },
            set: { month in
                let year = YearMonth(session.filter.startDate).year
                if let value = YearMonth(year: year, month: month) {
                    session.filter.startDate = value.startDate
                }
            })
    }
    private var selectedYear: Binding<Int> {
        Binding(
            get: { YearMonth(session.filter.startDate).year },
            set: { year in
                let month = YearMonth(session.filter.startDate).month
                if let value = YearMonth(year: year, month: month) {
                    session.filter.startDate = value.startDate
                }
            })
    }

    @ViewBuilder
    var toggleDateMenu: some View {
        @Bindable var session = session
        Menu {
            Toggle(isOn: $session.filter.isFilteringByDate) {
                CashlyText("Filter by Date")
            }

            if session.filter.isFilteringByDate {
                let months = CashlyCalendar.current.monthSymbols
                let currentYear = YearMonth(.now).year
                let years = ((currentYear - 5)...(currentYear + 5))

                Divider()

                Menu {
                    Picker(selection: selectedMonth) {
                        ForEach(Array(months.enumerated()), id: \.offset) { index, month in
                            CashlyText(month.capitalized)
                                .tag(index + 1)
                        }
                    } label: {
                        EmptyView()
                    }
                } label: {
                    CashlyText(
                        session.filter.startDate.formatted(.dateTime.month(.wide)).capitalized)
                }
                Menu {
                    Picker(selection: selectedYear) {
                        ForEach(years, id: \.self) { year in
                            CashlyText(String(year))
                                .tag(year)
                        }
                    } label: {
                        EmptyView()
                    }
                } label: {
                    CashlyText(session.filter.startDate.formatted(.dateTime.year()))
                }

                if YearMonth(session.filter.startDate) != YearMonth(.now) {
                    Divider()

                    Button {
                        session.filter.startDate = .now
                    } label: {
                        CashlyLabel("Today", symbol: "location")
                    }
                }
            }
        } label: {
            CashlyLabel("Date", symbol: "calendar")
        }
        .cashly(tint: .text)
    }

    @ViewBuilder
    var categoriesMenu: some View {
        @Bindable var session = session
        CashlyMenuSelectionView(
            items: finance.allCategories,
            selectedItems: $session.filter.categories
        ) { category in
            CashlyText(category.name.capitalized)
        } label: {
            CashlyLabel("Categories", symbol: "swatchpalette")
            if session.filter.categories.count > .zero {
                CashlyText("\(session.filter.categories.count) selected")
            }
        }
        .cashly(tint: .text)
    }

    @ViewBuilder
    var tagsMenu: some View {
        @Bindable var session = session
        CashlyMenuSelectionView(
            items: finance.allTags,
            selectedItems: $session.filter.tags
        ) { tag in
            CashlyText(tag.name.capitalized)
        } label: {
            CashlyLabel("Tags", symbol: "tag")
            if session.filter.tags.count > .zero {
                CashlyText("\(session.filter.tags.count) selected")
            }
        }
        .cashly(tint: .text)
    }

    @ViewBuilder
    var statusesMenu: some View {
        @Bindable var session = session
        CashlyMenuSelectionView(
            items: finance.allStatuses,
            selectedItems: $session.filter.transactionStatuses
        ) { status in
            CashlyText(status.summary)
        } label: {
            CashlyLabel("Statuses", symbol: "text.pad.header.badge.clock")
            if session.filter.transactionStatuses.count > .zero {
                CashlyText("\(session.filter.transactionStatuses.count) selected")
            }
        }
        .cashly(tint: .text)
    }

    @ViewBuilder
    var participantsMenu: some View {
        @Bindable var session = session
        CashlyMenuSelectionView(
            items: session.users,
            selectedItems: $session.filter.participants
        ) { user in
            CashlyText(user.name)
        } label: {
            CashlyLabel("Participants", symbol: "person.2")
            if session.filter.participants.count > .zero {
                CashlyText("\(session.filter.participants.count) selected")
            }
        }
        .cashly(tint: .text)
    }

    @ViewBuilder
    var cleanMenu: some View {
        if !session.filter.isFilteringByDate
            || (session.filter.isFilteringByDate
                && YearMonth(session.filter.startDate) != YearMonth(.now))
            || !session.filter.categories.isEmpty || !session.filter.tags.isEmpty
            || !session.filter.transactionStatuses.isEmpty || !session.filter.participants.isEmpty
        {
            Divider()
            Button {
                session.filter.isFilteringByDate = true
                session.filter.startDate = Date.now
                session.filter.categories = []
                session.filter.tags = []
                session.filter.transactionStatuses = []
                session.filter.participants = []
            } label: {
                CashlyLabel("Clear", symbol: "eraser.line.dashed")
            }
            .cashly(tint: .text)
        }
    }

}

public enum FilterItem: Int, Identifiable, CaseIterable {
    case date
    case categories
    case tags
    case statuses
    case participants

    public var id: Int {
        rawValue
    }
}
