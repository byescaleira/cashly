import CashlyResource
import SwiftUI

public struct UserMenu: View {
    @Environment(SessionModel.self) private var session
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    public init() {}

    public var body: some View {
        @Bindable var session = session
        Menu {
            if !session.users.isEmpty {
                Picker(selection: $session.userSelection) {
                    ForEach(session.users) { user in
                        HStack {
                            avatar(user.photo)
                            Text(user.name.capitalized)
                        }
                        .tag(Optional(user))
                    }
                } label: {
                    EmptyView()
                }
                Divider()
            }
            if let user = session.user {
                Button("Editar usuário", systemImage: "pencil") {
                    open(.addUser(id: user.id), in: section)
                }
            }
            Button("Adicionar usuário", systemImage: "plus") {
                open(.addUser(id: nil), in: section)
            }
        } label: {
            avatar(session.user?.photo)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .accessibilityLabel("Usuário")
    }

    private func avatar(_ photo: String?) -> some View {
        CashlyResourceImage.avatar(id: photo)
            .resizable()
            .scaledToFit()
            .frame(width: 36, height: 36)
    }
}
