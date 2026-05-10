//
//  AddTransactionScreen+Handlers.swift
//  CashlyKit
//
//  Side-effect handlers and state-update helpers split out from
//  AddTransactionScreen.swift to keep that file at <= 250 lines (Wave 7 G019).
//

import SwiftUI
import CashlyDomain

extension AddTransactionScreen {
    func handlerPrediction() {
        switch predictionResult {
        case .textClassification(let value):
            let category = value.lowercased()
            store.state.budget = state.budgets.first(where: {
                $0.category.name.lowercased() == category
            }) ?? state.budget
        default:
            break
        }
    }

    func handlerInitialState() async {
        if let initialState {
            store.state = initialState
        }
        try? await Task.sleep(for: .seconds(0.5))
        action(.addTransaction(.fetch))
    }

    func onChangeSelectedUsers() {
        guard selectedUsers.count != store.state.participants.count else { return }
        store.state.splitMode = selectedUsers.isEmpty ? nil : store.state.splitMode ?? .equal
        store.state.participants = selectedUsers.map {
            let splitValue: Double
            switch store.state.splitMode ?? .equal {
            case .equal: splitValue = (selectedUsers.count.double + 1)
            case .fixedAmount: splitValue = .zero
            case .percentage: splitValue = 1 / (selectedUsers.count.double + 1)
            case .payerBased: splitValue = .zero
            }
            return Participant(
                id: UUID().uuidString,
                user: $0,
                splitMode: store.state.splitMode ?? .equal,
                splitValue: splitValue,
                status: .settled,
                transaction: state.id
            )
        }.sorted { $0.user.name < $1.user.name }
    }

    func updateSplitValue() {
        if store.state.participants.count != selectedUsers.count {
            selectedUsers = Set(state.participants.map(\.user))
        }

        store.state.splitValue = store.state.participants.isEmpty ? nil : (store.state.amount - store.state.participants.compactMap {
            let value = $0.splitMode.value(splitValue: $0.splitValue, amount: store.state.amount)
            return value
        }.reduce(.zero, +))
    }

    func participantBinding(at index: Int) -> Binding<Participant> {
        Binding {
            guard store.state.participants.indices.contains(index) else { return .empty }
            return store.state.participants[index]
        } set: { participant in
            guard store.state.participants.indices.contains(index) else { return }
            store.state.participants[index] = participant
        }
    }

    func categoryItemView(category: CashlyDomain.Category) -> some View {
        CashlyButton {
            isActivePrediction = false
            store.state.budget = state.budgets.first(where: { $0.category.id == category.id })
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
