//
//  HomeScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 08/09/25.
//

import SwiftUI
import CashlyMock
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct HomeScreen: CashlyView {
    @EnvironmentObject var store: CashlyStore<MainReducer, MainMiddleware>
    
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    
    public init() {}
    
    public var body: some View {
        CashlyList {
            BalanceView()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) { UserItemView() }
        }
        .onAppear { action(.main(.fetch)) }
        .navigationTitle((state.user?.selfFirstName ?? "") + "Home")
    }
    
    public static var mock: some View {
        HomeScreen()
    }
}

#Preview {
    NavigationView {
        HomeScreen
            .cashlyPreview()
    }
}
