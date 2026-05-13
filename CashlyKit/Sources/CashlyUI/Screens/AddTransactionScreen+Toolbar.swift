//
//  AddTransactionScreen+Toolbar.swift
//  CashlyKit
//
//  Toolbar items split out from AddTransactionScreen.swift.
//

import SwiftUI
import CashlyDomain
import CashlyResource

extension AddTransactionScreen {
    @ViewBuilder
    var participantsItem: some View {
        let users = mainState.users.filter { $0.id != mainState.user?.id }
        if !users.isEmpty {
            CashlyMenuSelectionView(
                items: users,
                selectedItems: $selectedUsers
            ) { user in
                CashlyText(user.name.capitalized)
            } label: {
                CashlySymbol("person.2.badge.plus.fill")
                    .cashly(color: .text)
                    .accessibilityLabel(CashlyL10n.string("Add participants"))
            }
        }
    }

    var saveButton: some View {
        CashlyButton {
            action(.addTransaction(.save))
        } label: {
            CashlySymbol("checkmark")
        }
        .buttonStyle(.glassProminent)
        .disabled(!state.canSave)
        .cashly(tint: state.canSave ? .primary : .disabled)
        .accessibilityLabel(CashlyL10n.string("Save transaction"))
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !state.isLoading {
            CashlyButton {
                action(.addTransaction(.remove))
            } label: {
                CashlySymbol("trash")
            }
            .cashly(tint: .text)
            .accessibilityLabel(CashlyL10n.string("Delete"))
            .accessibilityAddTraits(.isButton)
        }
    }

    @ViewBuilder
    var dictationItem: some View {
        CashlyButton {
            Task { await toggleDictation() }
        } label: {
            CashlySymbol(isDictating ? "stop.circle.fill" : "mic.fill")
        }
        .cashly(tint: isDictating ? .color(.red) : .text)
        .accessibilityLabel(CashlyL10n.string(isDictating ? "Stop dictation" : "Dictate transaction"))
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    var intelligenceItem: some View {
        if let user,
           let model = CashlyIntelligence.categoryName.model(for: user),
           model.createDate != nil,
           !isActivePrediction {
            CashlyButton {
                isActivePrediction = true
            } label: {
                CashlySymbol("bolt.fill")
            }
            .accessibilityLabel(CashlyL10n.string("Enable AI prediction"))
            .accessibilityAddTraits(.isButton)
        }
    }
}
