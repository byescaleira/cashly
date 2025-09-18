//
//  MainScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 09/09/25.
//

import SwiftUI
import CashlyMock
import CashlyPresentation

public struct MainScreen: CashlyView {
    @EnvironmentObject var store: CashlyStore<MainReducer, MainMiddleware>
    
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    
    @State var tabItem: MainTabItem = .home
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $tabItem) {
            Tab("Categories", systemImage: "tag", value: .category) {
                CashlyNavigationView(
                    router: $store.state.categoryRouter,
                    destination: destination(_:)
                ) {
                    CategoryScreen()
                }
                .environment(\.router, store.state.categoryRouter)
            }
            
            Tab("Home", systemImage: "house", value: .home) {
                CashlyNavigationView(
                    router: $store.state.homeRouter,
                    destination: destination(_:)
                ) {
                    HomeScreen()
                }
                .environment(\.router, store.state.homeRouter)
            }
            
            Tab("Transactions", systemImage: "wallet.bifold", value: .transaction) {
                CashlyNavigationView(
                    router: $store.state.transactionRouter,
                    destination: destination(_:)
                ) {
                    TransactionScreen()
                }
                .environment(\.router, store.state.transactionRouter)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
    
    @ViewBuilder
    func destination(_ route: MainRoute) -> any View {
        switch route {
        case let .addUser(state): AddUserScreen(initialState: state)
        case let .addCategory(state): AddCategoryScreen( initialState: state)
        case let .addBudget(state): AddBudgetScreen(initialState: state)
        case let .addTransaction(state): AddTransactionScreen(initialState: state)
        case let .addTag(state): AddTagScreen(initialState: state)
        case let .detailCategory(category): DetailCategoryScreen(category: category)
        case .category: CategoryScreen()
        case .transaction: TransactionScreen()
        case .home: HomeScreen()
        }
    }
    
    public static var mock: some View {
        MainScreen()
    }
}

enum MainTabItem: Int, Hashable, Identifiable, CaseIterable {
    case category
    case home
    case transaction
    
    var id: Int { rawValue }
}

#Preview {
    MainScreen
        .cashlyPreview()
}
