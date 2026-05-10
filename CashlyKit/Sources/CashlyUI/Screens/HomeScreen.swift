//
//  HomeScreen.swift
//  CashlyKit
//
//  Wave 7 G019: body + @State only. Sections live in HomeScreen+*.swift.
//

import SwiftUI
#if DEBUG
import CashlyMock
#endif
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct HomeScreen: CashlyView {
    @Environment(CashlyStore<MainReducer, MainMiddleware>.self) var store

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
            ToolbarItem { FilterItemView() }
        }
        .onAppear { action(.main(.fetch)) }
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
