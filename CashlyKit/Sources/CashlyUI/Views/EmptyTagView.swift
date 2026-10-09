import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import Foundation
import SwiftUI

struct EmptyTagView: View {
    @Environment(\.isLoading) var isLoading
    @Environment(SessionModel.self) var session
    @Environment(FinanceModel.self) var finance
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    @ViewBuilder
    var body: some View {
        if !finance.categories.isEmpty,
            !session.users.isEmpty,
            finance.tags.isEmpty,
            !isLoading
        {
            Section {
                ZStack {
                    if finance.tags.isEmpty {
                        EmptyStateCard(
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
                .animation(.bouncy, value: finance.categories.isEmpty)
                .animation(.bouncy, value: session.users.isEmpty)
                .animation(.bouncy, value: finance.tags.isEmpty)
            } header: {
                CashlyText("Tags")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
            .transition(.scale)
        }
    }

}
