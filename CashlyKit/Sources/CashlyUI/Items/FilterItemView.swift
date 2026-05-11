//
//  FilterItemView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 16/09/25.
//

import SwiftUI
import CashlyDomain
import CashlyResource
import CashlyPresentation
#if DEBUG
import CashlyMock
#endif

struct FilterItemView: CashlyView {
    @Environment(CashlyStore<MainState, MainAction>.self) var store

    @Environment(\.mainState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router

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
           !state.filter.allCategories.isEmpty {
            Menu {
                if contains(.date) {
                    toggleDateMenu
                    Divider()
                }

                if contains(.categories), !state.filter.allCategories.isEmpty {
                    categoriesMenu
                }

                if contains(.tags), !state.filter.allTags.isEmpty {
                    tagsMenu
                }

                if contains(.statuses), !state.filter.allTransactions.isEmpty {
                    statusesMenu
                }

                if contains(.participants), !state.users.isEmpty, !state.filter.allTransactions.isEmpty {
                    participantsMenu
                }

                cleanMenu
            } label: {
                CashlySymbol("line.3.horizontal.decrease")
                    .cashly(color: .text)
                    .accessibilityLabel(CashlyL10n.string("Filter"))
                    .accessibilityAddTraits(.isButton)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
        }
    }

    @State var month: String = ""
    @State var year: Int = .zero

    @ViewBuilder
    var toggleDateMenu: some View {
        return Menu {
            Toggle(isOn: store.cashlyBinding(\.filter).isFilteringByDate) {
                CashlyText(CashlyL10n.string("Filter by Date"))
            }

            if state.filter.isFilteringByDate {
                let months = Calendar.current.monthSymbols
                let currentYear = Date.now.string(with: .cashly(.year))?.int ?? .zero
                let years = ((currentYear - 5) ... (currentYear + 5))

                Divider()

                Menu {
                    Picker(selection: $month) {
                        ForEach(months, id: \.self) { month in
                            CashlyText(month.capitalized)
                                .tag(month)
                        }
                    } label: {
                        EmptyView()
                    }
                } label: {
                    CashlyText(state.filter.startDate.string(with: .cashly(.month))?.capitalized)
                }
                .onAppear {
                    month = month.isEmpty ? state.filter.startDate.string(with: .cashly(.month)) ?? "" : month
                    year = year == .zero ? state.filter.startDate.string(with: .cashly(.year))?.int ?? .zero : year
                }
                .onChange(of: month) { updateDate() }

                Menu {
                    Picker(selection: $year) {
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
                .onChange(of: year) { updateDate() }

                if state.filter.startDate.timeIntervalSince1970.yearMonth != Date.now.timeIntervalSince1970.yearMonth {
                    Divider()

                    CashlyButton {
                        store.cashlyMutate(\.filter.startDate, .now)
                    } label: {
                        CashlyLabel(CashlyL10n.string("Today"), symbol: "location")
                    }
                }
            }
        } label: {
            CashlyLabel(CashlyL10n.string("Date"), symbol: "calendar")
        }
        .cashly(tint: .text)
    }

    func updateDate() {
        let month = month.date(with: .cashly(.month))?.string(with: .cashly(.numberMonth))?.int ?? 0
        let date = ((year * 100) + month).string.date(with: .cashly(.yearMonth)) ?? .now
        store.cashlyMutate(\.filter.startDate, date)
    }

    @ViewBuilder
    var categoriesMenu: some View {
        CashlyMenuSelectionView(
            items: state.filter.allCategories,
            selectedItems: store.cashlyBinding(\.filter).categories
        ) { category in
            CashlyText(category.name.capitalized)
        } label: {
            CashlyLabel(CashlyL10n.string("Categories"), symbol: "swatchpalette")
            if state.filter.categories.count > .zero {
                CashlyText(state.filter.categories.count.string.space + "selected")
            }
        }
        .cashly(tint: .text)
    }

    @ViewBuilder
    var tagsMenu: some View {
        CashlyMenuSelectionView(
            items: state.filter.allTags,
            selectedItems: store.cashlyBinding(\.filter).tags
        ) { tag in
            CashlyText(tag.name.capitalized)
        } label: {
            CashlyLabel(CashlyL10n.string("Tags"), symbol: "tag")
            if state.filter.tags.count > .zero {
                CashlyText(state.filter.tags.count.string.space + "selected")
            }
        }
        .cashly(tint: .text)
    }

    @ViewBuilder
    var statusesMenu: some View {
        CashlyMenuSelectionView(
            items: state.filter.allStatuses,
            selectedItems: store.cashlyBinding(\.filter).transactionStatuses
        ) { status in
            CashlyText(status.summary)
        } label: {
            CashlyLabel(CashlyL10n.string("Statuses"), symbol: "text.pad.header.badge.clock")
            if state.filter.transactionStatuses.count > .zero {
                CashlyText(state.filter.transactionStatuses.count.string.space + "selected")
            }
        }
        .cashly(tint: .text)
    }

    @ViewBuilder
    var participantsMenu: some View {
        CashlyMenuSelectionView(
            items: state.users,
            selectedItems: store.cashlyBinding(\.filter).participants
        ) { user in
            CashlyText(user.name)
        } label: {
            CashlyLabel(CashlyL10n.string("Participants"), symbol: "person.2")
            if state.filter.participants.count > .zero {
                CashlyText(state.filter.participants.count.string.space + "selected")
            }
        }
        .cashly(tint: .text)
    }

    @ViewBuilder
    var cleanMenu: some View {
        if !state.filter.isFilteringByDate ||
            (state.filter.isFilteringByDate && state.filter.startDate.timeIntervalSince1970.yearMonth != Date.now.timeIntervalSince1970.yearMonth) ||
            !state.filter.categories.isEmpty ||
            !state.filter.tags.isEmpty ||
            !state.filter.transactionStatuses.isEmpty ||
            !state.filter.participants.isEmpty {
            Divider()
            CashlyButton {
                var filter = store.state.filter
                filter.isFilteringByDate = true
                filter.startDate = Date.now
                filter.categories = []
                filter.tags = []
                filter.transactionStatuses = []
                filter.participants = []
                store.cashlyMutate(\.filter, filter)
            } label: {
                CashlyLabel(CashlyL10n.string("Clear"), symbol: "eraser.line.dashed")
            }
            .cashly(tint: .text)
        }
    }

    static var mock: some View {
        FilterItemView()
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

#if DEBUG
#Preview {
    NavigationView {
        CashlyList {

        }
        .toolbar {
            ToolbarItem { FilterItemView.cashlyPreview() }
        }
    }
}
#endif
