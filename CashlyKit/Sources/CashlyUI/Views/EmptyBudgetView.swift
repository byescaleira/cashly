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
    var budgets: [Budget]
    
    @ViewBuilder
    var body: some View {
        if budgets.isEmpty, !state.categories.isEmpty {
            Section {
                CashlyCardView(
                    image: .illustrationNoData,
                    title: "No Budgets Found",
                    subtitle: "You don’t have any budgets yet. Start by creating one to manage your expenses.",
                    buttonTitle: "Create Budget"
                ) {
                    
                }
                .cashlyPadding(.medium)
            }
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
}

