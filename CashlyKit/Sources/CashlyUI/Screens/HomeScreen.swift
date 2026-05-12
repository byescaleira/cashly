//
//  HomeScreen.swift
//  CashlyKit
//
//  //  body + @State only. Sections live in HomeScreen+*.swift.
//

import SwiftUI
#if DEBUG
import CashlyMock
#endif
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct HomeScreen: CashlyView {
    @Environment(CashlyStore<MainState, MainAction>.self) var store

    @Environment(\.mainState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router

    @State var selectedTag: Tag?
    @State var selectedCompareCategory: CashlyDomain.Category?
    @State var selectedAvailableCategory: CashlyDomain.Category?
    @State var selectedBiggestTransactionIndex: Int = .zero

    public init() {}

    public var body: some View {
        CashlyList {
            BalanceView()
            availableSection
            varianceSection
            biggestTransactionSection
            tagsSection
            spendingForecastSection
        }
        .toolbar {
            ToolbarItem(placement: .navigation) { UserItemView() }
            ToolbarItem { ProBadgeView(isPro: state.isPro) }
            ToolbarItem { settingsButton }
            ToolbarItem { FilterItemView() }
        }
        .onAppear { action(.main(.fetch)) }
        .cashlyErrorAlert(error: state.error) { store.cashlyMutate(\.error, nil) }
        .navigationTitle((state.user?.selfFirstName ?? "") + CashlyL10n.string("Home"))
    }

    var settingsButton: some View {
        CashlyButton {
            router.route(to: .settings)
        } label: {
            CashlySymbol("gearshape")
        }
        .cashly(tint: .text)
        .accessibilityLabel(CashlyL10n.string("Settings"))
    }

    public static var mock: some View {
        HomeScreen()
    }
}

#if DEBUG
#Preview {
    NavigationView {
        HomeScreen
            .cashlyPreview()
    }
}
#endif
