//
//  FilterItemView.swift
//  CashlyKit
//
//  Toolbar filter menu shell. Date sub-menu lives in +DateMenu,
//  multi-select menus + clean action in +SelectionMenus.
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

    @State var month: String = ""
    @State var year: Int = .zero

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
