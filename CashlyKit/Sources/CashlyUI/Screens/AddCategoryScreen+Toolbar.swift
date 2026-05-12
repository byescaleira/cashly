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
            CashlyHStack(spacing: .extraSmall) {
                if state.isNew, !mainState.canAdd(.addCategory) {
                    CashlySymbol("lock.fill")
                        .cashly(font: .caption)
                }
                CashlySymbol("checkmark")
            }
        }
        .buttonStyle(.glassProminent)
        .disabled(!state.canSave)
        .cashly(tint: state.canSave ? .primary : .disabled)
        .accessibilityLabel(CashlyL10n.string("Save"))
    }

    /// "n/N" usage chip shown next to the save button on Free tier.
    /// Hidden on Pro and during edit (gate only fires on create).
    @ViewBuilder
    var usageItem: some View {
        if state.isNew, !mainState.isPro {
            CashlyText(mainState.usageLabel(for: .addCategory))
                .cashly(font: .caption2, weight: .semibold)
                .cashly(color: mainState.canAdd(.addCategory) ? .textSecondary : .color(.yellow))
                .cashlyPadding(.horizontal, .small)
                .cashlyPadding(.vertical, .extraSmall)
                .cashly(background: .color(.secondary.opacity(0.2)))
                .cashly(clip: .capsule)
        }
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
