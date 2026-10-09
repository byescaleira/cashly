import CashlyResource
import SwiftUI

public struct UserMenu: View {
    @Environment(SessionModel.self) private var session
    @Environment(CashlyNavigation.self) private var navigation
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    #if os(macOS)
        @Environment(\.openSettings) private var openSettings
    #endif

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
            Divider()
            Button("Ajustes", systemImage: "gearshape") { showSettings() }
        } label: {
            avatar(session.user?.photo)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .accessibilityLabel("Usuário")
    }

    private func showSettings() {
        #if os(macOS)
            openSettings()
        #else
            navigation.isShowingSettings = true
        #endif
    }

    private func avatar(_ photo: String?) -> some View {
        CashlyResourceImage.avatar(id: photo)
            .resizable()
            .scaledToFit()
            .frame(width: 36, height: 36)
    }
}
