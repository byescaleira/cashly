//
//  MockModifier.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import SwiftUI
import CashlyPresentation

struct MockModifier: ViewModifier {
    @State var addCategoryStore: CashlyStore<AddCategoryState, AddCategoryAction>
    @State var addBudgetStore: CashlyStore<AddBudgetState, AddBudgetAction>
    @State var addTransactionStore: CashlyStore<AddTransactionState, AddTransactionAction>
    @State var addUserStore: CashlyStore<AddUserState, AddUserAction>
    @State var addTagStore: CashlyStore<AddTagState, AddTagAction>
    @State var mainStore: CashlyStore<MainState, MainAction>
    @State var paywallStore: CashlyStore<PaywallState, PaywallAction>

    init() {
        let factory = MockCashlyFactory()
        _addCategoryStore = State(initialValue: factory.makeAddCategoryStore())
        _addBudgetStore = State(initialValue: factory.makeAddBudgetStore())
        _addTransactionStore = State(initialValue: factory.makeAddTransactionStore())
        _addUserStore = State(initialValue: factory.makeAddUserStore())
        _addTagStore = State(initialValue: factory.makeAddTagStore())
        _mainStore = State(initialValue: factory.makeMainStore())
        _paywallStore = State(initialValue: factory.makePaywallStore(trigger: .upgradeButton))
    }

    func body(content: Content) -> some View {
        content
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
            .onChange(of: mainStore.state.user) { selectUser() }

            .task { handler(action: .main(.fetch)) }
            .task {
                let subscription = MockCashlyFactory().makeSubscriptionUseCase()
                for await status in subscription.statusUpdates() {
                    handler(action: .main(.subscriptionUpdated(status)))
                }
            }

            .tint(Color.accentColor)
    }

    @MainActor
    func handler(action: ApplicationAction) {
        let addCategory = addCategoryStore
        let addBudget = addBudgetStore
        let addTransaction = addTransactionStore
        let addUser = addUserStore
        let addTag = addTagStore
        let main = mainStore
        let paywall = paywallStore
        Task(priority: .high) { @MainActor in
            switch action {
            case let .addCategory(action): await addCategory.dispatch(action: action)
            case let .addBudget(action): await addBudget.dispatch(action: action)
            case let .addTransaction(action): await addTransaction.dispatch(action: action)
            case let .addUser(action): await addUser.dispatch(action: action)
            case let .addTag(action): await addTag.dispatch(action: action)
            case let .main(action): await main.dispatch(action: action)
            case let .paywall(action): await paywall.dispatch(action: action)
            }
        }
    }

    func selectUser() {
        handler(action: .main(.selectUser))
    }
}
