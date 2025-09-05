//
//  EmptyUserView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

import SwiftUI
import CashlyDomain

struct EmptyUserView: CashlyView {
    @Environment(\.mainState) var state
    
    @ViewBuilder
    var body: some View {
        if state.users.isEmpty {
            Section {
                CashlyCardView(
                    image: .illustrationPeople,
                    title: "No Users Found",
                    subtitle: "You don’t have any users yet. Start by adding one to manage your team.",
                    buttonTitle: "Add User"
                ) {
                    
                }
                .cashlyPadding(.medium)
            }
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
