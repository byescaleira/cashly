import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureGuides
import FeatureJourney
import FeatureOnboarding
import FeatureSettings
import FeatureStore
import SwiftUI
import WidgetKit

public struct MainScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(IntelligenceModel.self) private var intelligence
    @Environment(CashlyNavigation.self) private var navigation
    @Environment(NotificationsModel.self) private var notifications
    @Environment(SettingsModel.self) private var settings
    @Environment(StoreModel.self) private var store
    @Environment(LaunchProgress.self) private var launch
    @Environment(\.featureFlags) private var flags
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase
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
            if !launch.isDismissed {
                SplashScreen(progress: launch.fraction, status: launch.status)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.4), value: launch.isDismissed)
        .sheet(item: $navigation.guide) { GuideScreen($0) }
        .sheet(item: $navigation.shopItem) { ShopItemScreen(item: $0) }
        .modifier(MCPImportPresenter())
        .modifier(SharingPresenter())
        .environment(
            \.showGuide,
            ShowGuideAction { [isPro = pro.isPro] in navigation.show($0, isPro: isPro) }
        )
        .sheet(isPresented: $navigation.isOnboarding) {
            ModelHost(OnboardingModel(session: session)) { OnboardingScreen() }
        }
        .onChange(of: session.needsOnboarding && launch.isDismissed, initial: true) {
            _, needs in
            if needs { navigation.isOnboarding = true }
        }
        .routeInspector(isPresented: navigation.isInspecting) {
            if let inspector = navigation.inspector {
                InspectorScreen(inspector: inspector)
            }
        }
        .onGeometryChange(for: CGFloat.self) {
            $0.size.width
        } action: {
            navigation.fit(width: $0)
        }
        .environment(
            \.open,
            CashlyDestination { route, section in
                navigation.open(route, in: section)
            }
        )
        .environment(\.routeView, RouteViewBuilder { RouteScreen(route: $0) })
        .environment(\.user, session.user)
        .environment(\.isLoading, finance.isLoading)
        .task { await session.start() }
        .task { await store.start() }
        .task(id: session.loadKey) { await finance.load() }
        .onChange(of: session.isReady(finance), initial: true) {
            if session.isReady(finance) { launch.finish(.month) }
        }
        .task(id: extrasKey) {
            let snapshot = await finance.publishSnapshot(focusCategoryID: settings.widgetCategoryID)
            if session.isReady(finance) { launch.finish(.extras) }
            if let snapshot { await notifications.review(snapshot) }
            await CashlyIndexer.refresh(categories: finance.allCategories)
            await notifications.reviewCaptures(
                for: session.user, repositories: session.repositories,
                categories: finance.allCategories)
        }
        .task(id: intelligence.key(revision: finance.datasetRevision)) {
            await intelligence.load()
        }
        .task(id: journeyKey) {
            guard session.isReady(finance), scenePhase == .active else {
                return
            }
            await JourneyModel.publish(session: session, status: journeyStatus)
        }
        .task(id: store.tenureKey) { await store.recordTenure() }
        .task(id: exclusivesKey) {
            guard store.hasRefreshed, session.hasLoadedUsers, !pro.isPro else { return }
            await settings.dropProIcon()
            await session.dropProPhotos()
        }
        .onChange(of: session.hasLoadedUsers, initial: true) {
            if session.hasLoadedUsers { launch.finish(.profiles) }
        }
        .onChange(of: store.hasRefreshed, initial: true) {
            if store.hasRefreshed { launch.finish(.pro) }
        }
        .task(id: launch.isComplete) {
            try? await Task.sleep(for: launch.isComplete ? .milliseconds(600) : .seconds(8))
            launch.dismiss()
        }
        .task(
            id: notifications.paymentsKey(userID: session.user?.id, generation: session.generation)
        ) {
            await notifications.schedulePayments(
                for: session.user?.id, repositories: session.repositories)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { WidgetCenter.shared.reloadAllTimelines() }
            #if os(iOS)
                if phase != .active { Task { await JourneyActivities.sync() } }
            #endif
        }
        .onChange(of: navigation.selectedSection) { navigation.closeInspectorOutsideSelection() }
        .onChange(of: session.user?.id) { old, new in
            if old != nil && old != new { navigation.reset() }
        }
        .errorAlert($finance.error)
        .errorAlert($session.error)
        .modifier(PaywallOffer())
        .modifier(DeepLinks())
        .modifier(WebSharingPresenter())
        .modifier(JourneyNotifications())
        .modifier(PrivacyShield())
        .sheet(isPresented: $navigation.isShowingPaywall) { PaywallScreen() }
        .environment(
            \.shop,
            ShopAccess(
                owned: store.owned, isPro: pro.isPro, price: { store.price(for: $0) },
                open: { navigation.shopItem = $0 },
                presentPro: { navigation.isShowingPaywall = true })
        )
        .environment(\.pro, pro)
    }

    private var extrasKey: String {
        "\(session.user?.id ?? ""):\(finance.datasetRevision):\(session.isReady(finance)):\(settings.widgetCategoryID ?? "")"
    }

    private var journeyKey: String {
        "\(extrasKey):\(journeyStatus.rawValue):\(scenePhase == .active)"
    }

    private var exclusivesKey: String {
        "\(store.hasRefreshed):\(session.hasLoadedUsers):\(pro.isPro)"
    }

    private var journeyStatus: JourneySnapshot.Status {
        sections.contains(.journey) ? .active : .hidden
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
            && !navigation.isOnboarding && !pro.isPro
    }

    func body(content: Content) -> some View {
        content.onChange(of: isDue, initial: true) { _, due in
            guard due, !hasOffered, store.isPaywallOfferDue() else { return }
            hasOffered = true
            store.markPaywallOffered()
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                navigation.isShowingPaywall = true
            }
        }
    }
}
