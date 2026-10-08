import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import CashlyResource
import Foundation
import SwiftUI

struct UserItemView: View {

    @Environment(MainViewModel.self) var state
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    var userSelection: Binding<User?> {
        Binding(
            get: { state.user },
            set: { user in
                guard let user else { return }
                Task { await state.selectUser(user) }
            })
    }
    @ViewBuilder
    var body: some View {
        @Bindable var state = state
        if !state.users.isEmpty {
            Menu {
                Picker(selection: userSelection) {
                    ForEach(state.users) { user in
                        CashlyHStack {
                            CashlyResourceImage.avatar(id: user.photo)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)

                            CashlyText(user.name.capitalized)
                        }
                        .tag(Optional(user))
                    }
                } label: {
                    EmptyView()
                }

                Divider()

                if let user = state.user {
                    Button {
                        open(.addUser(id: user.id), in: section)
                    } label: {
                        CashlyLabel("Edit User", symbol: "pencil")
                            .cashly(color: .text)
                    }
                }

                Button {
                    open(.addUser(id: nil), in: section)
                } label: {
                    CashlyLabel("Add User", symbol: "plus")
                        .cashly(color: .text)
                }
            } label: {
                CashlyResourceImage.avatar(id: state.user?.photo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
        }
    }

}
