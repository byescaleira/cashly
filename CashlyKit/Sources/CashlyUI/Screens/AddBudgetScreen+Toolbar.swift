//
//  AddBudgetScreen+Toolbar.swift
//  CashlyKit
//
//  Toolbar items for AddBudgetScreen: save, remove, and AI quick-fill.
//

import SwiftUI
import CashlyResource
import CashlyDomain
import CashlyPresentation

extension AddBudgetScreen {
    var saveButton: some View {
        CashlyButton {
            action(.addBudget(.save))
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
                action(.addBudget(.remove))
            } label: {
                CashlySymbol("trash")
            }
            .accessibilityLabel(CashlyL10n.string("Delete"))
            .cashly(tint: .text)
        }
    }

    @ViewBuilder
    var quickFillItem: some View {
        if let user,
           let model = CashlyIntelligence.budgetValue.model(for: user),
           model.createDate != nil {
            CashlyButton {
                predictionInput = .tabularData(
                    .budgetValue(
                        date: state.date.timeIntervalSince1970.yearMonth,
                        category: state.category?.name ?? ""
                    )
                )
            } label: {
                CashlySymbol("bolt.fill")
            }
            .cashly(tint: .color(.yellow))
        }
    }
}
