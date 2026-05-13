//
//  MainScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 09/09/25.
//

import SwiftUI
#if DEBUG
import CashlyMock
#endif
import CashlyPresentation
import CashlyResource

public struct MainScreen: CashlyView {
    @Environment(CashlyStore<MainState, MainAction>.self) var store

    @Environment(\.mainState) var state
    @Environment(\.action) var action
    @Environment(\.pendingDeeplink) var pendingDeeplink

    @State var tabItem: MainTabItem = .home

    @State var intelligenceRouter = CashlyRouter<MainRoute>()
    @State var categoryRouter = CashlyRouter<MainRoute>()
    @State var homeRouter = CashlyRouter<MainRoute>()
    @State var transactionRouter = CashlyRouter<MainRoute>()

    public init() {}

    public var body: some View {
        tabView
            .onChange(of: pendingDeeplink) { _, route in
                guard let route else { return }
                handleDeeplink(route)
            }
    }

    /// Routes the deeplink to the most appropriate tab + router pair.
    /// Tab routes (.home / .category / .transaction / .intelligence)
    /// snap the tab selection; sheet/push routes (paywall, settings,
    /// add*, detailCategory) push on the router of the currently
    /// active tab so the user stays in context.
    private func handleDeeplink(_ route: MainRoute) {
        switch route {
        case .home:
            tabItem = .home
        case .category, .detailCategory:
            tabItem = .category
            categoryRouter.route(to: route)
        case .transaction:
            tabItem = .transaction
        case .intelligence:
            tabItem = .intelligence
        case .paywall, .settings, .addUser, .addCategory,
             .addBudget, .addTransaction, .addTag:
            // Use the currently active tab's router so the user
            // stays where they were when the link landed.
            activeRouter.route(to: route)
        }
    }

    private var activeRouter: CashlyRouter<MainRoute> {
        switch tabItem {
        case .intelligence: return intelligenceRouter
        case .category: return categoryRouter
        case .home: return homeRouter
        case .transaction: return transactionRouter
        }
    }

    var tabView: some View {
        TabView(selection: $tabItem) {
            Tab(CashlyL10n.string("Intelligence"), systemImage: "cpu", value: .intelligence) {
                intelligenceScreen
            }

            Tab(CashlyL10n.string("Categories"), systemImage: "tag", value: .category) {
                categoriesScreen
            }

            Tab(CashlyL10n.string("Home"), systemImage: "house", value: .home) {
                homeScreen
            }

            Tab(CashlyL10n.string("Transactions"), systemImage: "wallet.bifold", value: .transaction) {
                transactionScreen
            }
        }
        #if os(iOS)
        .tabBarMinimizeBehavior(.onScrollDown)
        #endif
        .tabViewStyle(.sidebarAdaptable)
    }

    var intelligenceScreen: some View {
        CashlyNavigationView(
            router: $intelligenceRouter,
            destination: destination(_:)
        ) {
            IntelligenceScreen()
        }
        .environment(\.router, intelligenceRouter)
    }

    var categoriesScreen: some View {
        CashlyNavigationView(
            router: $categoryRouter,
            destination: destination(_:)
        ) {
            CategoryScreen()
        }
        .environment(\.router, categoryRouter)
    }

    var homeScreen: some View {
        CashlyNavigationView(
            router: $homeRouter,
            destination: destination(_:)
        ) {
            HomeScreen()
        }
        .environment(\.router, homeRouter)
    }

    var transactionScreen: some View {
        CashlyNavigationView(
            router: $transactionRouter,
            destination: destination(_:)
        ) {
            TransactionScreen()
        }
        .environment(\.router, transactionRouter)
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
        case .intelligence: IntelligenceScreen()
        case let .paywall(trigger):
            PaywallScreen()
                .onAppear { action(.paywall(.replace(.opened(from: trigger)))) }
        case .settings:
            SettingsScreen()
        }
    }

    public static var mock: some View {
        MainScreen()
    }
}

enum MainTabItem: Int, Hashable, Identifiable, CaseIterable {
    case intelligence
    case category
    case home
    case transaction

    var id: Int { rawValue }
}

#if DEBUG
#Preview {
    MainScreen
        .cashlyPreview()
}
#endif
