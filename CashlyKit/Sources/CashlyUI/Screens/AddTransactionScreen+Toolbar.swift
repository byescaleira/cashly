//
//  AddTransactionScreen+Toolbar.swift
//  CashlyKit
//
//  Toolbar items split out from AddTransactionScreen.swift (Wave 7 G019).
//

import SwiftUI
import CashlyDomain

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
        }
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
        }
    }
}
