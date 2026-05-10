//
//  EmptyBudgetView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

import SwiftUI
import CashlyDomain

struct EmptyBudgetView: CashlyView {
    @Environment(\.isLoading) var isLoading
    @Environment(\.mainState) var state
    @Environment(\.router) var router
    
    var budgets: [Budget]
    
    @ViewBuilder
    var body: some View {
        if budgets.isEmpty,
           !state.categories.isEmpty,
           !isLoading {
            Section {
                CashlyZStack {
                    if budgets.isEmpty,
                       !state.categories.isEmpty {
                        CashlyCardView(
                            image: .illustrationNoData,
                            title: "No Budgets Yet",
                            subtitle: "Budgets help you stay in control of your spending. Set a budget for your categories to track and manage expenses effectively.",
                            buttonTitle: "Add Budget"
                        ) {
                            router.route(to: .addBudget(state: .new()))
                        }
                        .cashlyPadding(.medium)
                    }
                }
                .animation(.bouncy, value: budgets.isEmpty)
                .animation(.bouncy, value: state.categories.isEmpty)
            } header: {
                CashlyText("Budgets")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
            .transition(.scale)
        }
    }
    
    static var mock: some View {
        EmptyBudgetView(budgets: [])
    }
}

#if DEBUG
import CashlyMock
#Preview {
    CashlyList {
        EmptyBudgetView.mock
    }
    .cashlyPreview()
}
#endif

