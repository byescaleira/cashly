import CashlyDesignSystem
import SwiftUI

public struct UserMenu: View {
    @Environment(SessionModel.self) private var session
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    @Environment(\.displayScale) private var displayScale
    @Environment(SharingModel.self) private var sharing: SharingModel?

    public init() {}

    public var body: some View {
        @Bindable var session = session
        Menu {
            if !session.users.isEmpty {
                Picker(selection: $session.userSelection) {
                    ForEach(session.users) { user in
                        Label {
                            Text(user.name.capitalized)
                            if user.isShared { Text("Shared") }
                        } icon: {
                            ProfileAvatar.image(for: user, size: .badgeS, scale: displayScale)
                                .renderingMode(.original)
                        }
                        .tag(Optional(user))
                    }
                } label: {
                    EmptyView()
                }
                Divider()
            }
            if let user = session.user {
                Button("Edit Profile", systemImage: "pencil") {
                    open(.addUser(id: user.id), in: section)
                }
            }
            Button("Add Profile", systemImage: "plus") {
                open(.addUser(id: nil), in: section)
            }
            if sharing?.isEnabled == true {
                Button("New Shared Profile", systemImage: "person.2.badge.plus") {
                    open(.addSharedProfile, in: section)
                }
            }
        } label: {
            ProfileAvatar(session.user, size: .badgeM)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .accessibilityLabel("Profile")
    }
}
