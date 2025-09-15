//
//  EmptyCategoryView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 04/09/25.
//

import SwiftUI
import CashlyDomain

struct EmptyCategoryView: CashlyView {
    @Environment(\.mainState) var state
    @Environment(\.router) var router
    
    @ViewBuilder
    var body: some View {
        if state.categories.isEmpty,
           !state.users.isEmpty {
            Section {
                CashlyZStack {
                    if state.categories.isEmpty {
                        CashlyCardView(
                            image: .illustrationEmpty,
                            title: "No Categories Found",
                            subtitle: "You don’t have any categories yet. Start by creating one to organize your expenses.",
                            buttonTitle: "Create Category"
                        ) {
                            router.route(to: .addCategory(state: .new()))
                        }
                        .cashlyPadding(.medium)
                    }
                }
                .animation(.bouncy, value: state.categories.isEmpty)
                .animation(.bouncy, value: state.users.isEmpty)
            } header: {
                CashlyText("Not Found")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
            .transition(.scale)
        }
    }
    
    static var mock: some View {
        EmptyCategoryView()
    }
}

#Preview {
    CashlyList {
        EmptyCategoryView.mock
    }
}
