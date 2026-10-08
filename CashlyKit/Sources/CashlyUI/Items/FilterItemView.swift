import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import CashlyResource
import FeatureCore
import Foundation
import SwiftUI

struct FilterItemView: View {

    @Environment(MainViewModel.self) var state
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
        if state.user != nil,
            !state.allCategories.isEmpty
        {
            Menu {
                if contains(.date) {
                    toggleDateMenu
                    Divider()
                }

                if contains(.categories), !state.allCategories.isEmpty {
                    categoriesMenu
                }

                if contains(.tags), !state.allTags.isEmpty {
                    tagsMenu
                }

                if contains(.statuses), state.hasTransactions {
                    statusesMenu
                }

                if contains(.participants), !state.users.isEmpty, state.hasTransactions {
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
            get: { YearMonth(state.filter.startDate).month },
            set: { month in
                let year = YearMonth(state.filter.startDate).year
                if let value = YearMonth(year: year, month: month) {
                    state.filter.startDate = value.startDate
                }
            })
    }
    private var selectedYear: Binding<Int> {
        Binding(
            get: { YearMonth(state.filter.startDate).year },
            set: { year in
                let month = YearMonth(state.filter.startDate).month
                if let value = YearMonth(year: year, month: month) {
                    state.filter.startDate = value.startDate
                }
            })
    }

    @ViewBuilder
    var toggleDateMenu: some View {
        @Bindable var state = state
        Menu {
            Toggle(isOn: $state.filter.isFilteringByDate) {
                CashlyText("Filter by Date")
            }

            if state.filter.isFilteringByDate {
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
                    CashlyText(state.filter.startDate.formatted(.dateTime.month(.wide)).capitalized)
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
                    CashlyText(state.filter.startDate.formatted(.dateTime.year()))
                }

                if YearMonth(state.filter.startDate) != YearMonth(.now) {
                    Divider()

                    Button {
                        state.filter.startDate = .now
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
        @Bindable var state = state
        CashlyMenuSelectionView(
            items: state.allCategories,
            selectedItems: $state.filter.categories
        ) { category in
            CashlyText(category.name.capitalized)
        } label: {
            CashlyLabel("Categories", symbol: "swatchpalette")
            if state.filter.categories.count > .zero {
                CashlyText("\(state.filter.categories.count) selected")
            }
        }
        .cashly(tint: .text)
    }

    @ViewBuilder
    var tagsMenu: some View {
        @Bindable var state = state
        CashlyMenuSelectionView(
            items: state.allTags,
            selectedItems: $state.filter.tags
        ) { tag in
            CashlyText(tag.name.capitalized)
        } label: {
            CashlyLabel("Tags", symbol: "tag")
            if state.filter.tags.count > .zero {
                CashlyText("\(state.filter.tags.count) selected")
            }
        }
        .cashly(tint: .text)
    }

    @ViewBuilder
    var statusesMenu: some View {
        @Bindable var state = state
        CashlyMenuSelectionView(
            items: state.allStatuses,
            selectedItems: $state.filter.transactionStatuses
        ) { status in
            CashlyText(status.summary)
        } label: {
            CashlyLabel("Statuses", symbol: "text.pad.header.badge.clock")
            if state.filter.transactionStatuses.count > .zero {
                CashlyText("\(state.filter.transactionStatuses.count) selected")
            }
        }
        .cashly(tint: .text)
    }

    @ViewBuilder
    var participantsMenu: some View {
        @Bindable var state = state
        CashlyMenuSelectionView(
            items: state.users,
            selectedItems: $state.filter.participants
        ) { user in
            CashlyText(user.name)
        } label: {
            CashlyLabel("Participants", symbol: "person.2")
            if state.filter.participants.count > .zero {
                CashlyText("\(state.filter.participants.count) selected")
            }
        }
        .cashly(tint: .text)
    }

    @ViewBuilder
    var cleanMenu: some View {
        if !state.filter.isFilteringByDate
            || (state.filter.isFilteringByDate
                && YearMonth(state.filter.startDate) != YearMonth(.now))
            || !state.filter.categories.isEmpty || !state.filter.tags.isEmpty
            || !state.filter.transactionStatuses.isEmpty || !state.filter.participants.isEmpty
        {
            Divider()
            Button {
                state.filter.isFilteringByDate = true
                state.filter.startDate = Date.now
                state.filter.categories = []
                state.filter.tags = []
                state.filter.transactionStatuses = []
                state.filter.participants = []
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
