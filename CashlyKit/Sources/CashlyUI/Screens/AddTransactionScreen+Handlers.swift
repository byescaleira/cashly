//
//  AddTransactionScreen+Handlers.swift
//  CashlyKit
//
//  Side-effect handlers and state-update helpers split out from
//  AddTransactionScreen.swift to keep that file at <= 250 lines.
//

import SwiftUI
import CashlyDomain

extension AddTransactionScreen {
    func handlerPrediction() {
        switch predictionResult {
        case .textClassification(let value):
            let category = value.lowercased()
            let matched = state.budgets.first(where: {
                $0.category.name.lowercased() == category
            }) ?? state.budget
            store.cashlyMutate(\.budget, matched)
        default:
            break
        }
    }

    func handlerInitialState() async {
        if let initialState {
            store.cashlyReplace(initialState)
        }
        await Task.yield()
        action(.addTransaction(.fetch))
    }

    func onChangeSelectedUsers() {
        guard selectedUsers.count != store.state.participants.count else { return }
        // Single atomic mutation — two cashlyMutate calls in a row
        // would each snapshot `state` independently and the second
        // replace could overwrite the first (lost-update race).
        let users = selectedUsers
        let stateId = state.id
        store.cashlyMutate { state in
            let resolvedSplitMode = users.isEmpty ? nil : state.splitMode ?? .equal
            state.splitMode = resolvedSplitMode
            state.participants = users.map { user -> Participant in
                let splitValue: Double
                switch resolvedSplitMode ?? .equal {
                case .equal: splitValue = (users.count.double + 1)
                case .fixedAmount: splitValue = .zero
                case .percentage: splitValue = 1 / (users.count.double + 1)
                case .payerBased: splitValue = .zero
                }
                return Participant(
                    id: UUID().uuidString,
                    user: user,
                    splitMode: resolvedSplitMode ?? .equal,
                    splitValue: splitValue,
                    status: .settled,
                    transaction: stateId
                )
            }.sorted { $0.user.name < $1.user.name }
        }
    }

    func updateSplitValue() {
        if store.state.participants.count != selectedUsers.count {
            selectedUsers = Set(state.participants.map(\.user))
        }

        let newSplitValue: Double? = store.state.participants.isEmpty ? nil : (store.state.amount - store.state.participants.compactMap {
            let value = $0.splitMode.value(splitValue: $0.splitValue, amount: store.state.amount)
            return value
        }.reduce(.zero, +))
        store.cashlyMutate(\.splitValue, newSplitValue)
    }

    func participantBinding(at index: Int) -> Binding<Participant> {
        Binding {
            guard store.state.participants.indices.contains(index) else { return .empty }
            return store.state.participants[index]
        } set: { participant in
            guard store.state.participants.indices.contains(index) else { return }
            var arr = store.state.participants
            arr[index] = participant
            store.cashlyMutate(\.participants, arr)
        }
    }

    func categoryItemView(category: CashlyDomain.Category) -> some View {
        CashlyButton {
            isActivePrediction = false
            store.cashlyMutate(\.budget, state.budgets.first(where: { $0.category.id == category.id }))
        } label: {
            CashlySymbol(category.icon)
                .cashly(font: .system(size: 20))
                .cashly(color: state.category == category ? .hex(category.color) : .color(.secondary))
                .frame(width: 45, height: 45)
                .cashly(background: .color((state.category == category ? Color(hex: category.color) : .secondary).opacity(0.2)))
                .cashly(clip: .circle)
                .overlay {
                    Circle()
                        .stroke(state.category == category ? Color(hex: category.color) : .secondary, lineWidth: 3)
                        .frame(width: 50, height: 50)
                }
                .opacity(state.category == category ? 1 : 0.3)
        }
        .buttonStyle(.plain)
        .cashlyPadding()
    }
}
