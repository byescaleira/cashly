//
//  UserItemView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

import SwiftUI
import CashlyDomain
import CashlyResource
import CashlyPresentation
#if DEBUG
import CashlyMock
#endif

struct UserItemView: CashlyView {
    @Environment(CashlyStore<MainState, MainAction>.self) var store

    @Environment(\.mainState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router

    @ViewBuilder
    var body: some View {
        if !state.users.isEmpty {
            Menu {
                Section(CashlyL10n.string("Switch user")) {
                    ForEach(state.users) { user in
                        Button {
                            store.cashlyMutate(\.user, user)
                            CashlyHaptic.selection.play()
                        } label: {
                            // Menu rows mark the active user with a
                            // checkmark + show the avatar inline so
                            // the user can scan many accounts fast.
                            HStack {
                                Text(user.name.capitalized)
                                Spacer()
                                if user.id == state.user?.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Divider()

                if let user = state.user {
                    CashlyButton {
                        router.route(to: .addUser(state: .edit(id: user.id)))
                    } label: {
                        CashlyLabel(CashlyL10n.string("Edit User"), symbol: "pencil")
                            .cashly(color: .text)
                    }
                }

                CashlyButton {
                    router.route(to: .addUser(state: .new()))
                } label: {
                    CashlyLabel(CashlyL10n.string("Add User"), symbol: "plus")
                        .cashly(color: .text)
                }
            } label: {
                avatarChip
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: state.user?.name.capitalized ?? CashlyL10n.string("User")))
            .accessibilityHint(Text(CashlyL10n.string("Tap to switch user")))
        }
    }

    /// Avatar tile with the current user's name initial fallback +
    /// a Pro crown badge in the corner when the user is on the Pro
    /// tier. Animates the swap so multi-user nav reads as polished.
    private var avatarChip: some View {
        ZStack(alignment: .bottomTrailing) {
            CashlyResourceImage.avatar(id: store.state.user?.photo)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .overlay {
                    if (state.user?.photo).map({ $0.isEmpty }) ?? true {
                        Text(initial)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .clipShape(.circle)
                .id(state.user?.id ?? "")
                .transition(.opacity.combined(with: .scale))
            if state.isPro {
                Image(systemName: "crown.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.yellow)
                    .padding(3)
                    .background(.thinMaterial, in: Circle())
                    .offset(x: 2, y: 2)
                    .accessibilityHidden(true)
            }
        }
        .animation(.snappy, value: state.user?.id)
    }

    private var initial: String {
        guard let name = state.user?.name, let char = name.first else { return "?" }
        return String(char).uppercased()
    }

    static var mock: some View {
        UserItemView()
    }
}

#if DEBUG
#Preview {
    NavigationView {
        CashlyList {

        }
        .toolbar {
            ToolbarItem { UserItemView.cashlyPreview() }
        }
    }
}
#endif
