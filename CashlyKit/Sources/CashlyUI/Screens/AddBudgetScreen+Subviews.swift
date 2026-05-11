//
//  AddBudgetScreen+Subviews.swift
//  CashlyKit
//
//  Category picker subviews for AddBudgetScreen.
//

import SwiftUI
import CashlyDomain

extension AddBudgetScreen {
    @ViewBuilder
    var categoriesView: some View {
        if !state.categories.isEmpty {
            CashlyHorizontalList { proxy in
                CashlyHStack {
                    ForEach(state.categories) { category in
                        categoryItemView(category: category)
                            .id(category)
                    }
                }
                .cashlyPadding(.horizontal, .medium)
                .onChange(of: state.category) {
                    withAnimation(.bouncy) {
                        proxy.scrollTo(state.category, anchor: .center)
                    }
                }
            }
            .cashlyPadding(.horizontal, .negative(.medium))
        }
    }

    func categoryItemView(category: CashlyDomain.Category) -> some View {
        CashlyButton {
            store.cashlyMutate(\.category, category)
        } label: {
            CashlySymbol(category.icon)
                .cashly(font: .system(size: 20))
                .cashly(color: state.category == category ? .hex(category.color) : .color(.secondary))
                .frame(width: 45, height: 45)
                .cashly(background: .color((state.category == category ? Color(hex: category.color) : .secondary).opacity(0.2)))
                .cashly(clip: .circle)
                .overlay {
                    Circle()
                        .stroke(state.category == category ? Color(hex: category.color) : .secondary, lineWidth: 3)
                        .frame(width: 50, height: 50)
                }
                .opacity(state.category == category ? 1 : 0.3)
        }
        .buttonStyle(.plain)
        .cashlyPadding()
    }
}
