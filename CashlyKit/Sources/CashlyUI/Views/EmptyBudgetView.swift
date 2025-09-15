//
//  EmptyBudgetView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

import SwiftUI
import CashlyDomain

struct EmptyBudgetView: CashlyView {
    @Environment(\.mainState) var state
    @Environment(\.router) var router
    
    var budgets: [Budget]
    
    @ViewBuilder
    var body: some View {
        if budgets.isEmpty,
           !state.categories.isEmpty {
            Section {
                CashlyZStack {
                    if budgets.isEmpty,
                       !state.categories.isEmpty {
                        CashlyCardView(
                            image: .illustrationNoData,
                            title: "No Budgets Found",
                            subtitle: "You don’t have any budgets yet. Start by creating one to manage your expenses.",
                            buttonTitle: "Create Budget"
                        ) {
                            router.route(to: .addBudget(state: .new()))
                        }
                        .cashlyPadding(.medium)
                    }
                }
                .animation(.bouncy, value: budgets.isEmpty)
                .animation(.bouncy, value: state.categories.isEmpty)
            } header: {
                CashlyText("Not Found")
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

#Preview {
    CashlyList {
        EmptyBudgetView.mock
    }
    .cashlyPreview()
}

