import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureGuides
import FeatureJourney
import FeatureOnboarding
import FeatureSettings
import FeatureStore
import SwiftUI

public struct MainScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(IntelligenceModel.self) private var intelligence
    @Environment(CashlyNavigation.self) private var navigation
    @Environment(NotificationsModel.self) private var notifications
    @Environment(SettingsModel.self) private var settings
    @Environment(StoreModel.self) private var store
    @Environment(\.featureFlags) private var flags
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.locale) private var locale
    public init() {}

    @ViewBuilder
    public var body: some View {
        @Bindable var navigation = navigation
        @Bindable var session = session
        @Bindable var finance = finance
        TabView(selection: $navigation.selectedSection) {
            ForEach(sections) { section in
                Tab(
                    section.title, systemImage: section.systemImage, value: section,
                    role: section.role
                ) {
                    SectionStack(section: section)
                }
            }
        }
        .id(locale.identifier)
        .tabViewStyle(.sidebarAdaptable)
        .overlay {
            if !session.isReady(finance) {
                LaunchView().transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: session.isReady(finance))
        .sheet(item: $navigation.guide) { GuideScreen($0) }
        .sheet(item: $navigation.shopItem) { ShopItemScreen(item: $0) }
        .environment(
            \.shop, ShopAccess(owned: store.owned) { navigation.shopItem = $0 }
        )
        .modifier(MCPImportPresenter())
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
            CashlyDestination { [canWrite = pro.canWrite] route, section in
                if route.requiresPro, !canWrite {
                    navigation.isShowingPaywall = true
                } else {
                    navigation.open(route, in: section, beside: horizontalSizeClass == .regular)
                }
            }
        )
        .environment(\.user, session.user)
        .environment(\.isLoading, finance.isLoading)
        .task { await session.start() }
        .task { await store.start() }
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
        .modifier(PaywallOffer())
        .sheet(isPresented: $navigation.isShowingPaywall) { PaywallScreen() }
        .environment(\.pro, pro)
    }

    private var pro: ProAccess {
        ProAccess(entitlement: store.entitlement, isEnforced: flags?.isOn(.pro) != false) {
            navigation.isShowingPaywall = true
        }
    }

    private var sections: [AppSection] {
        let showsJourney = settings.showsJourney && flags?.isOn(.journey) != false
        return AppSection.allCases.filter { $0 != .journey || showsJourney }
    }
}

private struct PaywallOffer: ViewModifier {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(StoreModel.self) private var store
    @Environment(CashlyNavigation.self) private var navigation
    @Environment(\.pro) private var pro
    @State private var hasOffered = false

    private var isDue: Bool {
        store.hasRefreshed && session.isReady(finance) && !session.needsOnboarding
            && !navigation.isOnboarding && !pro.canWrite
    }

    func body(content: Content) -> some View {
        content.onChange(of: isDue, initial: true) { _, due in
            guard due, !hasOffered else { return }
            hasOffered = true
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                navigation.isShowingPaywall = true
            }
        }
    }
}
