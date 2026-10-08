import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import FeatureCore
import Foundation
import SwiftUI

struct EmptyCategoryView: View {
    @Environment(\.isLoading) var isLoading
    @Environment(SessionModel.self) var session
    @Environment(FinanceModel.self) var finance
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    @ViewBuilder
    var body: some View {
        if finance.categories.isEmpty,
            !session.users.isEmpty,
            !isLoading
        {
            Section {
                ZStack {
                    if finance.categories.isEmpty {
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
                .animation(.bouncy, value: finance.categories.isEmpty)
                .animation(.bouncy, value: session.users.isEmpty)
            } header: {
                CashlyText("Categories")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
            .transition(.scale)
        }
    }

}
