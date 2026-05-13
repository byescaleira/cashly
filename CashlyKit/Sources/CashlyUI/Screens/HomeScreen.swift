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
            if state.reachability == .offline {
                offlineBanner
            }
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
            ToolbarItem { insightsButton }
            ToolbarItem { settingsButton }
            ToolbarItem { FilterItemView() }
        }
        .onAppear { action(.main(.fetch)) }
        .cashlyErrorAlert(error: state.error) { store.cashlyMutate(\.error, nil) }
        .navigationTitle((state.user?.selfFirstName ?? "") + CashlyL10n.string("Home"))
    }

    /// Cached-data warning. CloudKit + SwiftData keep working offline,
    /// so the banner is informational — no blocking modal.
    var offlineBanner: some View {
        Section {} header: {
            CashlyHStack(spacing: .small) {
                CashlySymbol("wifi.slash")
                    .accessibilityHidden(true)
                CashlyText(CashlyL10n.string("Offline — showing cached data."))
                    .cashly(font: .caption, weight: .semibold)
            }
            .cashly(color: .color(.white))
            .cashlyPadding(.horizontal, .medium)
            .cashlyPadding(.vertical, .small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cashly(background: .color(.orange))
            .cashly(clip: .capsule)
            .accessibilityElement(children: .combine)
        }
    }

    var insightsButton: some View {
        CashlyButton {
            router.route(to: .insights)
        } label: {
            CashlySymbol("chart.bar.xaxis")
        }
        .cashly(tint: .text)
        .accessibilityLabel(CashlyL10n.string("Insights"))
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
