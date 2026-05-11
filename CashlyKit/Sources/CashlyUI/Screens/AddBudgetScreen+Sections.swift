//
//  AddBudgetScreen+Sections.swift
//  CashlyKit
//
//  Form sections for AddBudgetScreen.
//

import SwiftUI
import CashlyResource
import CashlyDomain
import CashlyPresentation

extension AddBudgetScreen {
    var amountSection: some View {
        Section {} header: {
            CashlyVStack(spacing: .zero) {
                CashlyText(state.category?.name.uppercased())
                    .cashly(font: .caption, weight: .bold)
                    .cashly(color: .hex(state.category?.color))
                    .cashlyPadding()
                    .cashlyPadding(.horizontal, .extraSmall)
                    .cashly(glass: .clear.tint(Color(hex: state.category?.color).opacity(0.2)), in: .capsule)

                CashlyCurrencyTextField(amount: store.cashlyBinding(\.amount))
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .frame(maxWidth: .infinity)
                    .cashly(alignment: .center)
                    .cashly(font: .system(size: 40), weight: .black)
                    .cashlyPadding(.top, .medium)
                    .cashly(tint: .color(.clear))
            }
        }
    }

    var summarySection: some View {
        Section {
            TextField(
                "Provide a summary of your budget",
                text: store.cashlyBinding(\.summary),
                axis: .vertical
            )
        } header: {
            CashlyText(CashlyL10n.string("Summary"))
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }

    var categoriesSection: some View {
        Section {
            categoriesView
            EmptyCategoryView()
        } header: {
            CashlyText(CashlyL10n.string("Categories"))
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }

    var dateSection: some View {
        Section {
            DatePicker(
                "",
                selection: store.cashlyBinding(\.date),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .cashlyPadding(.vertical, .negative(.medium))
            .cashly(tint: .primary)
        } header: {
            CashlyText(CashlyL10n.string("Date"))
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }
}
