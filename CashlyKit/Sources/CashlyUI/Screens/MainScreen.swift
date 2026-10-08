import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import SwiftUI

public struct MainScreen: View {
    @Environment(MainViewModel.self) private var main
    @Environment(IntelligenceViewModel.self) private var intelligence
    @Environment(CashlyNavigation.self) private var navigation
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    public init() {}

    @ViewBuilder
    public var body: some View {
        @Bindable var navigation = navigation
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
        .environment(\.user, main.user)
        .environment(\.isLoading, main.isLoading)
        .task { await main.observeChanges() }
        .task(id: main.filter) { await main.load() }
        .task(id: (main.user?.id ?? "") + ":" + main.datasetRevision) {
            await intelligence.loadModels(user: main.user, revision: main.datasetRevision)
        }
        .onChange(of: main.user?.id) { old, new in
            if old != nil && old != new { navigation.reset() }
        }
        .cashlyErrorAlert(error: Binding(get: { main.error }, set: { main.error = $0 }))
    }

}
