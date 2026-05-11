//
//  AddCategoryScreen+Toolbar.swift
//  CashlyKit
//
//  Save + remove toolbar buttons for AddCategoryScreen.
//

import SwiftUI
import CashlyResource
import CashlyPresentation

extension AddCategoryScreen {
    var saveButton: some View {
        CashlyButton {
            action(.addCategory(.save))
        } label: {
            CashlySymbol("checkmark")
        }
        .buttonStyle(.glassProminent)
        .disabled(!state.canSave)
        .cashly(tint: state.canSave ? .primary : .disabled)
        .accessibilityLabel(CashlyL10n.string("Save"))
    }

    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !state.isLoading {
            CashlyButton {
                action(.addCategory(.remove))
            } label: {
                CashlySymbol("trash")
            }
            .cashly(tint: .text)
            .accessibilityLabel(CashlyL10n.string("Delete"))
        }
    }
}
