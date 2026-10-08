import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import CashlyResource
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
            get: { state.filter.startDate.timeIntervalSince1970.yearMonth % 100 },
            set: { month in
                let year = state.filter.startDate.timeIntervalSince1970.yearMonth / 100
                if let date = Date.from(yearMonth: year * 100 + month) {
                    state.filter.startDate = date
                }
            })
    }
    private var selectedYear: Binding<Int> {
        Binding(
            get: { state.filter.startDate.timeIntervalSince1970.yearMonth / 100 },
            set: { year in
                let month = state.filter.startDate.timeIntervalSince1970.yearMonth % 100
                if let date = Date.from(yearMonth: year * 100 + month) {
                    state.filter.startDate = date
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
                let currentYear = Date.now.string(with: .cashly(.year))?.int ?? .zero
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
                    CashlyText(state.filter.startDate.string(with: .cashly(.month))?.capitalized)
                }
                Menu {
                    Picker(selection: selectedYear) {
                        ForEach(years, id: \.self) { year in
                            CashlyText(year.string)
                                .tag(year)
                        }
                    } label: {
                        EmptyView()
                    }
                } label: {
                    CashlyText(state.filter.startDate.string(with: .cashly(.year))?.capitalized)
                }

                if state.filter.startDate.timeIntervalSince1970.yearMonth
                    != Date.now.timeIntervalSince1970.yearMonth
                {
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
                CashlyText(state.filter.categories.count.string.space + "selected")
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
                CashlyText(state.filter.tags.count.string.space + "selected")
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
                CashlyText(state.filter.transactionStatuses.count.string.space + "selected")
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
                CashlyText(state.filter.participants.count.string.space + "selected")
            }
        }
        .cashly(tint: .text)
    }

    @ViewBuilder
    var cleanMenu: some View {
        if !state.filter.isFilteringByDate
            || (state.filter.isFilteringByDate
                && state.filter.startDate.timeIntervalSince1970.yearMonth
                    != Date.now.timeIntervalSince1970.yearMonth)
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
