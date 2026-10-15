import CashlyDesignSystem
import SwiftUI

public struct UserMenu: View {
    @Environment(SessionModel.self) private var session
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    @Environment(\.displayScale) private var displayScale

    public init() {}

    public var body: some View {
        @Bindable var session = session
        Menu {
            if !session.users.isEmpty {
                Picker(selection: $session.userSelection) {
                    ForEach(session.users) { user in
                        Label {
                            Text(user.name.capitalized)
                        } icon: {
                            ProfileAvatar.image(for: user, size: .badgeS, scale: displayScale)
                        }
                        .tag(Optional(user))
                    }
                } label: {
                    EmptyView()
                }
                Divider()
            }
            if let user = session.user {
                Button("Edit User", systemImage: "pencil") {
                    open(.addUser(id: user.id), in: section)
                }
            }
            Button("Add User", systemImage: "plus") {
                open(.addUser(id: nil), in: section)
            }
        } label: {
            ProfileAvatar(session.user, size: .badgeM)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .accessibilityLabel("User")
    }
}
