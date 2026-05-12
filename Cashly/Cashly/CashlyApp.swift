//
//  CashlyApp.swift
//  Cashly
//

import SwiftUI
import SwiftData

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

    @AppStorage("cashly.onboarding.completed") var onboardingCompleted: Bool = false

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

                .environment(\.pendingDeeplink, pendingDeeplink)
                .onOpenURL { url in
                    pendingDeeplink = MainDeeplink.resolve(url)
                }
                .tint(Color.accentColor)
                .fullScreenCover(isPresented: Binding(
                    get: { !onboardingCompleted },
                    set: { onboardingCompleted = !$0 }
                )) {
                    OnboardingScreen()
                }
                #endif
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
