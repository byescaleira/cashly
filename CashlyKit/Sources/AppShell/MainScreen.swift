import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureGuides
import FeatureOnboarding
import SwiftUI

public struct MainScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(IntelligenceModel.self) private var intelligence
    @Environment(CashlyNavigation.self) private var navigation
    @Environment(NotificationsModel.self) private var notifications
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    public init() {}

    @ViewBuilder
    public var body: some View {
        @Bindable var navigation = navigation
        @Bindable var session = session
        @Bindable var finance = finance
        TabView(selection: $navigation.selectedSection) {
            ForEach(AppSection.allCases) { section in
                Tab(
                    section.title, systemImage: section.systemImage, value: section,
                    role: section.role
                ) {
                    SectionStack(section: section)
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .overlay {
            if !session.isReady(finance) {
                LaunchView().transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: session.isReady(finance))
        .sheet(item: $navigation.guide) { GuideScreen($0) }
        .environment(\.showGuide, ShowGuideAction { navigation.guide = $0 })
        .sheet(isPresented: $navigation.isOnboarding) {
            ModelHost(OnboardingModel(session: session)) { OnboardingScreen() }
        }
        .onChange(of: session.needsOnboarding && session.isReady(finance), initial: true) {
            _, needs in
            if needs { navigation.isOnboarding = true }
        }
        .routeInspector(isPresented: navigation.isInspecting) {
            if let inspector = navigation.inspector {
                InspectorScreen(inspector: inspector)
            }
        }
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
        .task(
            id: notifications.paymentsKey(userID: session.user?.id, generation: session.generation)
        ) {
            await notifications.schedulePayments(
                for: session.user?.id, repositories: session.repositories)
        }
        .onChange(of: navigation.selectedSection) { navigation.closeInspectorOutsideSelection() }
        .onChange(of: session.user?.id) { old, new in
            if old != nil && old != new { navigation.reset() }
        }
        .errorAlert($finance.error)
        .errorAlert($session.error)
    }
}
