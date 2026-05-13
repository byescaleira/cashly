//
//  CashlyApp.swift
//  Cashly
//

import SwiftUI
import SwiftData
import CoreData
import CoreSpotlight

import PrismArchitecture

import CashlyDomain
import CashlyData
import CashlyPresentation
import CashlyUI
#if DEBUG || targetEnvironment(simulator)
import CashlyMock
#endif

@main
struct CashlyApp: App {
    /// UIKit bridge for quick-action delivery on cold + warm launch.
    /// SwiftUI on its own cannot capture `launchOptions[.shortcutItem]`.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State var addCategoryStore: CashlyStore<AddCategoryState, AddCategoryAction>
    @State var addBudgetStore: CashlyStore<AddBudgetState, AddBudgetAction>
    @State var addTransactionStore: CashlyStore<AddTransactionState, AddTransactionAction>
    @State var addUserStore: CashlyStore<AddUserState, AddUserAction>
    @State var addTagStore: CashlyStore<AddTagState, AddTagAction>
    @State var mainStore: CashlyStore<MainState, MainAction>
    @State var paywallStore: CashlyStore<PaywallState, PaywallAction>

    /// Held so the StoreKit `Transaction.updates` listener stays alive
    /// for the app lifetime. Must be retained somewhere — the listener
    /// task is owned by the actor.
    let subscriptionService: SubscriptionUseCase
    let reachability: ReachabilityUseCase
    let syncStatus: SyncStatusUseCase
    let spotlight: SpotlightIndexerUseCase

    @AppStorage("cashly.onboarding.completed") var onboardingCompleted: Bool = false
    @AppStorage("cashly.appearance") var appearanceRaw: String = CashlyAppearance.system.rawValue

    private var appearance: CashlyAppearance {
        CashlyAppearance(rawValue: appearanceRaw) ?? .system
    }

    /// Latest deeplink resolved by `onOpenURL`. MainScreen reads it via
    /// the `pendingDeeplink` environment, forwards into its active tab
    /// router, and clears the slot back to nil.
    @State var pendingDeeplink: MainRoute?

    init() {
        let factory: CashlyPresentationFactory
        do {
            factory = try CashlyPresentationFactory()
        } catch {
            preconditionFailure("Failed to bootstrap CashlyPresentationFactory: \(error.localizedDescription)")
        }
        _addCategoryStore = State(initialValue: factory.makeAddCategoryStore())
        _addBudgetStore = State(initialValue: factory.makeAddBudgetStore())
        _addTransactionStore = State(initialValue: factory.makeAddTransactionStore())
        _addUserStore = State(initialValue: factory.makeAddUserStore())
        _addTagStore = State(initialValue: factory.makeAddTagStore())
        _mainStore = State(initialValue: factory.makeMainStore())
        _paywallStore = State(initialValue: factory.makePaywallStore(trigger: .upgradeButton))
        subscriptionService = factory.makeSubscriptionUseCase()
        reachability = factory.makeReachability()
        syncStatus = factory.makeSyncStatus()
        spotlight = factory.makeSpotlightIndexer()
    }

    var body: some Scene {
        WindowGroup {
            MainScreen()
                #if targetEnvironment(simulator)
                .cashlyPreview()
                #else
                .environment(addCategoryStore)
                .environment(addBudgetStore)
                .environment(addTransactionStore)
                .environment(addUserStore)
                .environment(addTagStore)
                .environment(mainStore)
                .environment(paywallStore)

                .environment(\.addCategoryState, addCategoryStore.state)
                .environment(\.addBudgetState, addBudgetStore.state)
                .environment(\.addTransactionState, addTransactionStore.state)
                .environment(\.addUserState, addUserStore.state)
                .environment(\.addTagState, addTagStore.state)
                .environment(\.mainState, mainStore.state)
                .environment(\.paywallState, paywallStore.state)

                .environment(\.action, handler(action:))

                .environment(\.isLoading, mainStore.state.isLoading)
                .environment(\.user, mainStore.state.user)

                .onChange(of: mainStore.state.filter) { handler(action: .main(.fetch)) }
                .onChange(of: mainStore.state.user) { handler(action: .main(.selectUser)) }
                .onChange(of: mainStore.state.transactions) { _, new in
                    // Push every fetch result through CoreSpotlight so
                    // OS-wide search surfaces Cashly transactions.
                    // Indexer is idempotent — replaces the whole domain.
                    Task { await spotlight.index(transactions: new) }
                }

                .task { handler(action: .main(.fetch)) }
                .task {
                    if let storeKit = subscriptionService as? StoreKitSubscriptionService {
                        await storeKit.start()
                    }
                }
                .task {
                    // Forward every subscription status emission into
                    // MainState so UI reacts to tier changes without
                    // having to poll the use case.
                    for await status in subscriptionService.statusUpdates() {
                        handler(action: .main(.subscriptionUpdated(status)))
                    }
                }
                .task {
                    // Forward NWPathMonitor emissions into MainState
                    // for the offline banner.
                    for await status in reachability.statusUpdates() {
                        handler(action: .main(.reachabilityUpdated(status)))
                    }
                }
                .task {
                    // Bootstrap MainState.syncStatus with whatever the
                    // persistence layer last recorded, then subscribe
                    // to NSPersistentCloudKitContainer events and
                    // re-publish on every successful export. macOS +
                    // visionOS get the same path.
                    let initial = await syncStatus.currentStatus()
                    handler(action: .main(.syncStatusUpdated(initial)))
                    for await _ in NotificationCenter.default.notifications(
                        named: NSPersistentCloudKitContainer.eventChangedNotification
                    ) {
                        let now = Date()
                        await syncStatus.markSynced(at: now)
                        let fresh = await syncStatus.currentStatus()
                        handler(action: .main(.syncStatusUpdated(fresh)))
                    }
                }

                .environment(\.pendingDeeplink, pendingDeeplink)
                .onOpenURL { url in
                    routeExternal(MainDeeplink.resolve(url))
                }
                .onContinueUserActivity(CSSearchableItemActionType) { activity in
                    routeExternal(MainDeeplink.resolve(activity))
                }
                .onChange(of: scenePhase) { _, phase in
                    // UIKit hands the quick-action type to AppDelegate;
                    // we forward it on every scene activation so both
                    // cold and warm launches reach routeExternal.
                    guard phase == .active,
                          let type = AppDelegate.launchShortcutType
                    else { return }
                    AppDelegate.launchShortcutType = nil
                    routeExternal(MainDeeplink.resolve(shortcutType: type))
                }
                .tint(Color.accentColor)
                .preferredColorScheme(appearance.colorScheme)
                .fullScreenCover(isPresented: $onboardingCompleted.inverted) {
                    OnboardingScreen(onUpgrade: {
                        routeExternal(.paywall(trigger: .upgradeButton))
                    })
                }
                #endif
        }
    }

    /// Single entry point for everything that wants to push a
    /// MainRoute from outside the SwiftUI hierarchy (onOpenURL,
    /// onboarding "Upgrade to Pro" button, future push notifications).
    /// Funnels through the same pendingDeeplink slot MainScreen
    /// observes, then clears it so a repeat-fire of the same route
    /// still re-pushes.
    func routeExternal(_ route: MainRoute?) {
        guard let route else { return }
        pendingDeeplink = route
        // Clear on the next runloop so onChange in MainScreen fires
        // again if the same route is dispatched twice.
        Task { @MainActor in
            await Task.yield()
            pendingDeeplink = nil
        }
    }

    func handler(action: ApplicationAction) {
        Task(priority: .high) { @MainActor in
            switch action {
            case let .addCategory(action): await addCategoryStore.dispatch(action: action)
            case let .addBudget(action): await addBudgetStore.dispatch(action: action)
            case let .addTransaction(action): await addTransactionStore.dispatch(action: action)
            case let .addUser(action): await addUserStore.dispatch(action: action)
            case let .addTag(action): await addTagStore.dispatch(action: action)
            case let .main(action): await mainStore.dispatch(action: action)
            case let .paywall(action): await paywallStore.dispatch(action: action)
            }
        }
    }
}
