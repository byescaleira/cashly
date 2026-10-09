import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import FeatureCore
import Foundation
import SwiftUI

struct EmptyBudgetView: View {
    @Environment(\.isLoading) var isLoading
    @Environment(FinanceModel.self) var finance
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    var budgets: [Budget]

    @ViewBuilder
    var body: some View {
        if budgets.isEmpty,
            !finance.categories.isEmpty,
            !isLoading
        {
            Section {
                ZStack {
                    if budgets.isEmpty,
                        !finance.categories.isEmpty
                    {
                        EmptyStateCard(
                            image: .illustrationNoData,
                            title: "No Budgets Yet",
                            subtitle:
                                "Budgets help you stay in control of your spending. Set a budget for your categories to track and manage expenses effectively.",
                            buttonTitle: "Add Budget"
                        ) {
                            open(.addBudget(id: nil, categoryID: nil, date: nil), in: section)
                        }
                        .cashlyPadding(.medium)
                    }
                }
                .animation(.bouncy, value: budgets.isEmpty)
                .animation(.bouncy, value: finance.categories.isEmpty)
            } header: {
                CashlyText("Budgets")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
            .transition(.scale)
        }
    }

}
