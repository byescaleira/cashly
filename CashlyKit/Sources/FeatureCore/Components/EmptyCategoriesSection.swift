import CashlyDesignSystem
import SwiftUI

public struct EmptyCategoriesSection: View {
    @Environment(\.isLoading) private var isLoading
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    public init() {}

    public var body: some View {
        if finance.categories.isEmpty, !session.users.isEmpty, !isLoading {
            Section {
                EmptyStateCard(
                    image: .illustrationEmpty,
                    title: "Nenhuma categoria ainda",
                    subtitle:
                        "Categorias mostram para onde vai o seu dinheiro. Crie a primeira para organizar os gastos.",
                    buttonTitle: "Adicionar categoria"
                ) {
                    open(.addCategory(id: nil), in: section)
                }
                .padding(16)
            } header: {
                Text("Categorias").sectionTitle()
            }
            .transition(.scale)
        }
    }
}
