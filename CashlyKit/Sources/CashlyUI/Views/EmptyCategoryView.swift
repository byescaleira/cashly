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
    
    @ViewBuilder
    var body: some View {
        if state.categories.isEmpty {
            Section {
                CashlyCardView(
                    image: .illustrationEmpty,
                    title: "No Categories Found",
                    subtitle: "You don’t have any categories yet. Start by creating one to organize your expenses.",
                    buttonTitle: "Create Category"
                ) {
                    
                }
                .cashlyPadding(.medium)
            }
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
