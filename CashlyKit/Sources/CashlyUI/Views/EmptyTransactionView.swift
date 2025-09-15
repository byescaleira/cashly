//
//  EmptyTransactionView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 11/09/25.
//

import SwiftUI
import CashlyDomain

struct EmptyTransactionView: CashlyView {
    @Environment(\.mainState) var state
    @Environment(\.router) var router
    
    @ViewBuilder
    var body: some View {
        if !state.categories.isEmpty,
           !state.budgets.isEmpty,
           !state.users.isEmpty,
           state.transactions.isEmpty {
            Section {
                CashlyZStack {
                    if state.transactions.isEmpty {
                        CashlyCardView(
                            image: .illustrationEmptyTransaction,
                            title: "No Transactions Found",
                            subtitle: "You don’t have any transactions yet. Start by adding one to track your expenses.",
                            buttonTitle: "Add Transaction",
                            size: 80
                        ) {
                            router.route(to: .addTransaction(state: .new()))
                        }
                        .cashlyPadding(.medium)
                    }
                }
                .animation(.bouncy, value: state.transactions.isEmpty)
            } header: {
                CashlyText("Not Found")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
            .transition(.scale)
        }
    }
    
    static var mock: some View {
        EmptyTransactionView()
    }
}

#Preview {
    CashlyList {
        EmptyTransactionView.mock
    }
}
