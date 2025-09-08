//
//  UserItemView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

import SwiftUI
import CashlyDomain
import CashlyPresentation
import CashlyMock

struct UserItemView: CashlyView {
    @EnvironmentObject var store: CashlyStore<MainReducer, MainMiddleware>
    
    @Environment(\.mainState) var state
    @Environment(\.user) var user
    @Environment(\.action) var action
    
    var body: some View {
        if let user {
            Menu {
                Picker(selection: $store.state.filter.user) {
                    ForEach(state.users) {
                        CashlyAsyncImage($0.photo) { image in
                            image
                        } placeholder: {
                            ProgressView()
                                .cashly(tint: .textSecondary)
                        }
                        .cashly(clip: .circle)
                        .tag($0)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.palette)
            } label: {
                CashlyAsyncImage(user.photo) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .cashly(clip: .circle)
                } placeholder: {
                    ProgressView()
                        .cashly(tint: .textSecondary)
                }
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
    CashlyList {
        UserItemView
            .cashlyPreview()
    }
}
