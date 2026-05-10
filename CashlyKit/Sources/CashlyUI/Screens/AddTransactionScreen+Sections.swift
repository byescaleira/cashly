//
//  AddTransactionScreen+Sections.swift
//  CashlyKit
//
//  Form sections split out from AddTransactionScreen.swift (Wave 7 G019).
//

import SwiftUI
import CashlyDomain

extension AddTransactionScreen {
    var amountSection: some View {
        @Bindable var store = store
        return Section {} header: {
            CashlyVStack(spacing: .small) {
                transactionStatusView
                splitValueView

                CashlyVStack(spacing: .zero) {
                    CashlyCurrencyTextField(amount: $store.state.amount)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .cashly(alignment: .center)
                        .cashly(font: .system(size: 40), weight: .black)
                        .cashly(tint: .color(.clear))

                    if state.installmentIsOn, state.amount > .zero {
                        let value = state.amount / state.installmentPlan.double
                        let description = "\(state.installmentPlan)x payments of \(value.currency() ?? "")"
                        CashlyText(description)
                            .cashly(font: .callout, weight: .medium)
                            .cashly(color: .textSecondary)
                            .contentTransition(.numericText())
                            .animation(.bouncy, value: state.amount)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .cashlyPadding(.vertical, .small)
        }
    }

    var summarySection: some View {
        @Bindable var store = store
        return Section {
            TextField(
                "Provide a summary of your transaction",
                text: $store.state.summary,
                axis: .vertical
            )
        } header: {
            CashlyText("Summary")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }

    var categoriesSection: some View {
        Section {
            categoriesView
            EmptyCategoryView()
            EmptyBudgetView(budgets: state.budgets)
        } header: {
            CashlyHStack {
                CashlyText("Categories")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
                CashlySpacer()
                CategoryVariationView(
                    category: state.category,
                    amount: state.amount
                )
            }
        } footer: {
            if let category = state.category {
                let remaining = mainState.categoryRemainingAmount(category: category) - state.amount
                let description = remaining < .zero ? "You’ve exceeded the planned budget in the \(category.name.capitalized) category by \((remaining * -1).currency() ?? "")" : "You’re \(remaining.currency() ?? "") away from reaching the planned budget in the \(category.name.capitalized) category."
                CashlyText(description)
                    .contentTransition(.numericText(value: remaining))
                    .animation(.bouncy, value: state.amount)
            }
        }
    }

    var dateSection: some View {
        @Bindable var store = store
        return Section {
            DatePicker(
                state.date.string(with: .cashly(.weekDay)) ?? "",
                selection: $store.state.date,
                displayedComponents: .hourAndMinute.union(.date)
            )
            .datePickerStyle(.compact)
            .cashly(tint: .primary)
        } header: {
            CashlyText("Date")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }

    @ViewBuilder
    var selectedParticipantsSection: some View {
        if !state.participants.isEmpty {
            Section {
                splitModeView
            } header: {
                CashlyText("Participants")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            } footer: {
                CashlyText(state.splitMode?.description)
            }

            participantsView
        }
    }

    var installmentSection: some View {
        @Bindable var store = store
        return Section {
            Toggle(isOn: $store.state.installmentIsOn) {
                CashlyText("Enable installments")
            }

            if state.installmentIsOn {
                Picker(selection: $store.state.installmentPlan) {
                    ForEach(1 ... 21, id: \.self) {
                        let value = $0.string + "x"
                        CashlyText(value)
                            .tag($0)
                    }
                } label: {
                    CashlyText("Number of installments")
                }
            }
        } header: {
            CashlyText("Installment")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }
}
