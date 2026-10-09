import CashlyDesignSystem
import SwiftUI

public struct EmptyUsersSection: View {
    @Environment(\.isLoading) private var isLoading
    @Environment(SessionModel.self) private var session
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    public init() {}

    public var body: some View {
        if session.users.isEmpty, !isLoading {
            Section {
                EmptyStateCard(
                    image: .illustrationPeople,
                    title: "Nenhum usuário ainda",
                    subtitle:
                        "Com usuários, você compartilha e organiza as finanças em equipe. Adicione o primeiro para começar.",
                    buttonTitle: "Adicionar usuário"
                ) {
                    open(.addUser(id: nil), in: section)
                }
                .padding(16)
                .animation(.bouncy, value: session.users.isEmpty)
            } header: {
                Text("Usuários").sectionTitle()
            }
            .transition(.scale)
        }
    }
}
