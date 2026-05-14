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
            pendingLoansSection
            biggestTransactionSection
            tagsSection
            insightsSection
            spendingForecastSection
        }
        .toolbar {
            ToolbarItem(placement: .navigation) { UserItemView() }
            ToolbarItem { FilterItemView() }
        }
        .onAppear { action(.main(.fetch)) }
        .refreshable {
            action(.main(.fetch))
            // Small yield so the pull-to-refresh spinner stays on
            // screen long enough to feel responsive instead of
            // disappearing instantly when the cache is already warm.
            try? await Task.sleep(nanoseconds: 400_000_000)
        }
        .cashlyErrorAlert(error: state.error) { store.cashlyMutate(\.error, nil) }
        .navigationTitle((state.user?.selfFirstName ?? "") + CashlyL10n.string("Home"))
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
