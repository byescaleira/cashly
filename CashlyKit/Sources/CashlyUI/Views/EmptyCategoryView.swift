import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import Foundation
import SwiftUI

struct EmptyCategoryView: View {
    @Environment(\.isLoading) var isLoading
    @Environment(MainViewModel.self) var state
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    @ViewBuilder
    var body: some View {
        if state.categories.isEmpty,
            !state.users.isEmpty,
            !isLoading
        {
            Section {
                ZStack {
                    if state.categories.isEmpty {
                        CashlyCardView(
                            image: .illustrationEmpty,
                            title: "No Categories Yet",
                            subtitle:
                                "Categories help you understand where your money goes. Create your first category to start organizing your expenses.",
                            buttonTitle: "Add Category"
                        ) {
                            open(.addCategory(id: nil), in: section)
                        }
                        .cashlyPadding(.medium)
                    }
                }
                .animation(.bouncy, value: state.categories.isEmpty)
                .animation(.bouncy, value: state.users.isEmpty)
            } header: {
                CashlyText("Categories")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
            .transition(.scale)
        }
    }

}
