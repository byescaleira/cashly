import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import Foundation
import SwiftUI

struct EmptyTagView: View {
    @Environment(\.isLoading) var isLoading
    @Environment(MainViewModel.self) var state
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    @ViewBuilder
    var body: some View {
        if !state.categories.isEmpty,
            !state.users.isEmpty,
            state.tags.isEmpty,
            !isLoading
        {
            Section {
                ZStack {
                    if state.tags.isEmpty {
                        CashlyCardView(
                            image: .illustrationTag,
                            title: "No Tags Yet",
                            subtitle:
                                "Tags help you categorize and track your expenses more easily. Start by creating your first tag to keep things organized.",
                            buttonTitle: "Add Tag"
                        ) {
                            open(.addTag(id: nil), in: section)
                        }
                        .cashlyPadding(.medium)
                    }
                }
                .animation(.bouncy, value: state.categories.isEmpty)
                .animation(.bouncy, value: state.users.isEmpty)
                .animation(.bouncy, value: state.tags.isEmpty)
            } header: {
                CashlyText("Tags")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
            .transition(.scale)
        }
    }

}
