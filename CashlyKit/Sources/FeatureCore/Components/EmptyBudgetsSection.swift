import CashlyDesignSystem
import SwiftUI

public struct EmptyBudgetsSection: View {
    @Environment(\.isLoading) private var isLoading
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    public init() {}

    public var body: some View {
        if finance.budgets.isEmpty, !finance.categories.isEmpty, !isLoading {
            Section {
                EmptyStateCard(
                    image: .illustrationNoData,
                    title: "Nenhum orçamento ainda",
                    subtitle:
                        "Orçamentos ajudam a controlar os gastos. Defina um valor para cada categoria e acompanhe o mês.",
                    buttonTitle: "Adicionar orçamento"
                ) {
                    open(.addBudget(id: nil, categoryID: nil, date: nil), in: section)
                }
                .padding(16)
            } header: {
                Text("Orçamentos").sectionTitle()
            }
            .transition(.scale)
        }
    }
}
