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
    let appLock: AppLockUseCase
    let transactionDictation: TransactionDictationUseCase
    let speechTranscriber: SpeechTranscriberUseCase
    let attachmentStorage: AttachmentStorageUseCase
    let recurringTransactions: RecurringTransactionUseCase
    let transactionUseCase: TransactionUseCase
    let budgetUseCase: BudgetUseCase
    let categoryUseCase: CategoryUseCase

    @State private var isLocked: Bool = false

    @AppStorage("cashly.onboarding.completed") var onboardingCompleted: Bool = false
    @AppStorage("cashly.appearance") var appearanceRaw: String = CashlyAppearance.system.rawValue
    /// K11: tracks whether the post-onboarding paywall has already
    /// been presented. Set to true the first time the flow runs so
    /// the user doesn't see it twice if onboarding is reopened
    /// programmatically.
    @AppStorage("cashly.paywall.postOnboardingSeen") var postOnboardingPaywallSeen: Bool = false

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
        appLock = factory.makeAppLock()
        transactionDictation = factory.makeTransactionDictation()
        speechTranscriber = factory.makeSpeechTranscriber()
        attachmentStorage = factory.makeAttachmentStorage()
        recurringTransactions = factory.makeRecurringTransactions()
        transactionUseCase = factory.makeTransactionUseCase()
        budgetUseCase = factory.makeBudgetUseCase()
        categoryUseCase = factory.makeCategoryUseCase()
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
                .environment(\.transactionDictation, transactionDictation)
                .environment(\.speechTranscriber, speechTranscriber)
                .environment(\.attachmentStorage, attachmentStorage)
                .environment(\.recurringTransactions, recurringTransactions)

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
                .task { await materializeRecurringTransactions() }
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
                    guard phase == .active else {
                        if phase == .background, isLocked == false {
                            Task { if await appLock.isEnabled() { isLocked = true } }
                        }
                        return
                    }
                    // UIKit hands the quick-action type to AppDelegate;
                    // forward on every activation so cold + warm
                    // launches both reach routeExternal.
                    if let type = AppDelegate.launchShortcutType {
                        AppDelegate.launchShortcutType = nil
                        routeExternal(MainDeeplink.resolve(shortcutType: type))
                    }
                    // AppIntents stash their target on a singleton when
                    // they run in-process; same drain channel.
                    if let route = PendingShortcutAction.shared.route {
                        PendingShortcutAction.shared.route = nil
                        switch route {
                        case .addTransaction:
                            routeExternal(.addTransaction(state: .new()))
                        case .insights:
                            routeExternal(.insights)
                        }
                    }
                    Task { await promptUnlockIfNeeded() }
                }
                .task { await promptUnlockIfNeeded() }
                .overlay {
                    if isLocked {
                        AppLockOverlay { Task { await promptUnlockIfNeeded() } }
                    }
                }
                .tint(Color.accentColor)
                .preferredColorScheme(appearance.colorScheme)
                .fullScreenCover(isPresented: $onboardingCompleted.inverted) {
                    OnboardingScreen(onUpgrade: {
                        routeExternal(.paywall(trigger: .upgradeButton))
                    })
                }
                .onChange(of: onboardingCompleted) { _, isCompleted in
                    // K11: when onboarding finishes for the first
                    // time on a Free tier user, give the UI a beat
                    // to settle then show the paywall. Pro users
                    // and repeat onboardings are skipped.
                    guard isCompleted,
                          !postOnboardingPaywallSeen,
                          !mainStore.state.isPro
                    else { return }
                    postOnboardingPaywallSeen = true
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 600_000_000)
                        routeExternal(.paywall(trigger: .upgradeButton))
                    }
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

    /// K12c: materializes every past-due recurring transaction
    /// since the last launch. Runs on app foreground; fetch follows
    /// up automatically after any inserts.
    func materializeRecurringTransactions() async {
        do {
            let categories = try await categoryUseCaseFetch()
            let budgets = try await budgetUseCaseFetch()
            try await recurringTransactions.materializeDue(now: .now) { template, date in
                guard let category = categories.first(where: { $0.id == template.categoryId })
                else { return }
                let budget = budgets.first(where: { $0.id == template.budgetId })
                try await transactionUseCase.addTransaction(
                    id: UUID().uuidString,
                    participants: [],
                    budget: budget,
                    amount: template.amount,
                    date: date,
                    summary: template.summary,
                    status: .settled,
                    splitMode: nil,
                    splitValue: nil,
                    paymentsPlan: nil,
                    kind: template.kind,
                    needsReview: false,
                    category: category,
                    attachmentPath: nil
                )
            }
            handler(action: .main(.fetch))
        } catch {
            // Quiet failure — surface via crash reporter if/when
            // wired; user can still add transactions manually.
        }
    }

    private func categoryUseCaseFetch() async throws -> [CashlyDomain.Category] {
        try await categoryUseCase.getCategories()
    }

    private func budgetUseCaseFetch() async throws -> [Budget] {
        try await budgetUseCase.getBudgets()
    }

    @MainActor
    func promptUnlockIfNeeded() async {
        guard await appLock.isEnabled() else { isLocked = false; return }
        let outcome = await appLock.authenticate(reason: "Unlock Cashly")
        switch outcome {
        case .unlocked, .unavailable: isLocked = false
        case .failed: isLocked = true
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
