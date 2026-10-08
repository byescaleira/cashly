import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import FeatureCore
import SwiftUI

public struct MainScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(IntelligenceModel.self) private var intelligence
    @Environment(CashlyNavigation.self) private var navigation
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    public init() {}

    @ViewBuilder
    public var body: some View {
        @Bindable var navigation = navigation
        @Bindable var session = session
        @Bindable var finance = finance
        TabView(selection: $navigation.selectedSection) {
            ForEach(CashlySection.allCases) { section in
                Tab(section.title, systemImage: section.systemImage, value: section) {
                    NavigationStack(path: navigation.path(for: section)) {
                        CashlySectionScreen(section: section)
                            .navigationDestination(for: MainRoute.self) {
                                CashlyRouteScreen(route: $0)
                            }
                    }
                    .environment(\.navigationSection, section)
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        #if os(iOS)
            .tabBarMinimizeBehavior(.onScrollDown)
        #endif
        .sheet(item: $navigation.sheet) { sheet in
            CashlySheetScreen(destination: sheet)
        }
        .environment(
            \.open,
            CashlyDestination { route, section in
                navigation.open(route, in: section, asSheet: horizontalSizeClass == .regular)
            }
        )
        .environment(\.user, session.user)
        .environment(\.isLoading, finance.isLoading)
        .task { await session.start() }
        .task(id: session.loadKey) { await finance.load() }
        .task(id: (session.user?.id ?? "") + ":" + finance.datasetRevision) {
            await intelligence.loadModels(revision: finance.datasetRevision)
        }
        .onChange(of: session.user?.id) { old, new in
            if old != nil && old != new { navigation.reset() }
        }
        .cashlyErrorAlert(error: $finance.error)
        .cashlyErrorAlert(error: $session.error)
    }

}
