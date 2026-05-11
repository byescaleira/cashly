//
//  EmptyTagView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 16/09/25.
//

import SwiftUI
import CashlyResource
import CashlyDomain

struct EmptyTagView: CashlyView {
    @Environment(\.isLoading) var isLoading
    @Environment(\.mainState) var state
    @Environment(\.router) var router

    @ViewBuilder
    var body: some View {
        if !state.categories.isEmpty,
           !state.users.isEmpty,
            state.tags.isEmpty,
           !isLoading {
            Section {
                CashlyZStack {
                    if state.tags.isEmpty {
                        CashlyCardView(
                            image: .illustrationTag,
                                title: "No Tags Yet",
                                subtitle: "Tags help you categorize and track your expenses more easily. Start by creating your first tag to keep things organized.",
                                buttonTitle: "Add Tag"
                        ) {
                            router.route(to: .addTag(state: .new()))
                        }
                        .cashlyPadding(.medium)
                    }
                }
                .animation(.bouncy, value: state.categories.isEmpty)
                .animation(.bouncy, value: state.users.isEmpty)
                .animation(.bouncy, value: state.tags.isEmpty)
            } header: {
                CashlyText(CashlyL10n.string("Tags"))
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
            .transition(.scale)
        }
    }

    static var mock: some View {
        EmptyTagView()
    }
}

#Preview {
    CashlyList {
        EmptyTagView.mock
    }
}
