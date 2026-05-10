//
//  EmptyCategoryView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 04/09/25.
//

import SwiftUI
import CashlyResource
import CashlyDomain

struct EmptyCategoryView: CashlyView {
    @Environment(\.isLoading) var isLoading
    @Environment(\.mainState) var state
    @Environment(\.router) var router
    
    @ViewBuilder
    var body: some View {
        if state.categories.isEmpty,
           !state.users.isEmpty,
           !isLoading {
            Section {
                CashlyZStack {
                    if state.categories.isEmpty {
                        CashlyCardView(
                            image: .illustrationEmpty,
                            title: "No Categories Yet",
                            subtitle: "Categories help you understand where your money goes. Create your first category to start organizing your expenses.",
                            buttonTitle: "Add Category"
                        ) {
                            router.route(to: .addCategory(state: .new()))
                        }
                        .cashlyPadding(.medium)
                    }
                }
                .animation(.bouncy, value: state.categories.isEmpty)
                .animation(.bouncy, value: state.users.isEmpty)
            } header: {
                CashlyText(CashlyL10n.string("Categories"))
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
