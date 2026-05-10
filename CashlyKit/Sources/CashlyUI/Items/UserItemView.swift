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
import CashlyMock

struct UserItemView: CashlyView {
    @Environment(CashlyStore<MainReducer, MainMiddleware>.self) var store
    
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router
    
    @ViewBuilder
    var body: some View {
        if !state.users.isEmpty {
            Menu {
                Picker(selection: $store.state.user) {
                    ForEach(state.users) { user in
                        CashlyHStack {
                            CashlyResourceImage.avatar(id: user.photo)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                            
                            CashlyText(user.name.capitalized)
                        }
                        .tag(user)
                    }
                } label: {
                    EmptyView()
                }
                
                Divider()
                
                if let user = state.user {
                    CashlyButton {
                        router.route(to: .addUser(state: .edit(id: user.id)))
                    } label: {
                        CashlyLabel("Edit User", symbol: "pencil")
                            .cashly(color: .text)
                    }
                }
                
                CashlyButton {
                    router.route(to: .addUser(state: .new()))
                } label: {
                    CashlyLabel("Add User", symbol: "plus")
                        .cashly(color: .text)
                }
            } label: {
                CashlyResourceImage.avatar(id: store.state.user?.photo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
        }
    }
    
    static var mock: some View {
        UserItemView()
    }
}

#Preview {
    NavigationView {
        CashlyList {
              
        }
        .toolbar {
            ToolbarItem { UserItemView.cashlyPreview() }
        }
    }
}
