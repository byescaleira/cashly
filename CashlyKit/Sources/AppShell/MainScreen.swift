import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureSettings
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
            ForEach(AppSection.allCases) { section in
                Tab(section.title, systemImage: section.systemImage, value: section) {
                    SectionStack(section: section)
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .routeInspector(isPresented: navigation.isInspecting) {
            if let inspector = navigation.inspector {
                InspectorScreen(inspector: inspector)
            }
        }
        .sheet(isPresented: $navigation.isShowingSettings) {
            NavigationStack { SettingsScreen() }
        }
        #if os(iOS)
            .tabBarMinimizeBehavior(.onScrollDown)
        #endif
        .environment(
            \.open,
            CashlyDestination { route, section in
                navigation.open(route, in: section, beside: horizontalSizeClass == .regular)
            }
        )
        .environment(\.user, session.user)
        .environment(\.isLoading, finance.isLoading)
        .task { await session.start() }
        .task(id: session.loadKey) { await finance.load() }
        .task(id: (session.user?.id ?? "") + ":" + finance.datasetRevision) {
            await intelligence.loadModels(revision: finance.datasetRevision)
        }
        .onChange(of: navigation.selectedSection) { navigation.closeInspectorOutsideSelection() }
        .onChange(of: session.user?.id) { old, new in
            if old != nil && old != new { navigation.reset() }
        }
        .errorAlert($finance.error)
        .errorAlert($session.error)
    }

}
