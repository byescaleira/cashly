import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct EmptyTagsSection: View {
    @Environment(\.isLoading) private var isLoading
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        if !finance.categories.isEmpty, !session.users.isEmpty, finance.tags.isEmpty, !isLoading {
            Section {
                EmptyStateCard(
                    image: .illustrationTag,
                    title: "Nenhuma tag ainda",
                    subtitle:
                        "Tags ajudam a classificar e acompanhar os gastos. Crie a primeira para manter tudo organizado.",
                    buttonTitle: "Adicionar tag"
                ) {
                    open(.addTag(id: nil), in: section)
                }
                .padding(16)
            } header: {
                Text("Tags").sectionTitle()
            }
            .transition(.scale)
        }
    }
}
