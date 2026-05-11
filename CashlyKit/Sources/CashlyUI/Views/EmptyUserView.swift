//
//  EmptyUserView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

import SwiftUI
import CashlyResource
import CashlyDomain

struct EmptyUserView: CashlyView {
    @Environment(\.isLoading) var isLoading
    @Environment(\.mainState) var state
    @Environment(\.router) var router

    @ViewBuilder
    var body: some View {
        if state.users.isEmpty,
           !isLoading {
            Section {
                CashlyZStack {
                    if state.users.isEmpty {
                        CashlyCardView(
                            image: .illustrationPeople,
                            title: "No Users Yet",
                            subtitle: "Users let you share and manage your finances as a team. Add your first user to start collaborating.",
                            buttonTitle: "Add User"
                        ) {
                            router.route(to: .addUser(state: .new()))
                        }
                        .cashlyPadding(.medium)
                    }
                }
                .animation(.bouncy, value: state.users.isEmpty)
            } header: {
                CashlyText(CashlyL10n.string("Users"))
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
            .transition(.scale)
        }
    }

    static var mock: some View {
        EmptyUserView()
    }
}

#Preview {
    CashlyList {
        EmptyUserView.mock
    }
}
