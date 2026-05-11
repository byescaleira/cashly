//
//  FilterItemView+SelectionMenus.swift
//  CashlyKit
//
//  Multi-select menus (categories, tags, statuses, participants) used
//  by FilterItemView.
//

import SwiftUI
import CashlyResource

extension FilterItemView {
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
}
