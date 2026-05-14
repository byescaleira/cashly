//
//  ManageRecurringScreen.swift
//  CashlyKit
//
//  K12c. Lists every recurring template + lets the user remove
//  one. Add flow is a sheet that captures summary/amount/category/
//  cadence. Materialization runs at launch from CashlyApp.
//

import SwiftUI
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct ManageRecurringScreen: CashlyView {
    @Environment(\.mainState) var state
    @Environment(\.recurringTransactions) var recurringTransactions

    @State private var templates: [RecurringTransactionTemplate] = []
    @State private var showAddSheet: Bool = false

    public init() {}

    public var body: some View {
        CashlyList {
            if templates.isEmpty {
                CashlyText(CashlyL10n.string("No recurring transactions yet."))
                    .cashly(color: .textSecondary)
            } else {
                ForEach(templates, id: \.id) { template in
                    row(for: template)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await delete(template) }
                            } label: {
                                Label(
                                    CashlyL10n.string("Delete"),
                                    systemImage: "trash"
                                )
                            }
                        }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                CashlyButton {
                    showAddSheet = true
                } label: {
                    CashlySymbol("plus")
                }
            }
        }
        .navigationTitle(CashlyL10n.string("Recurring"))
        .task { await reload() }
        .sheet(isPresented: $showAddSheet) {
            AddRecurringSheet { template in
                Task {
                    try? await recurringTransactions.add(template)
                    await reload()
                }
            }
        }
    }

    @ViewBuilder
    private func row(for template: RecurringTransactionTemplate) -> some View {
        CashlyHStack(spacing: .small) {
            CashlySymbol(template.kind.icon)
                .cashly(color: .textSecondary)
            CashlyVStack(alignment: .leading, spacing: .extraSmall) {
                CashlyText(template.summary)
                    .cashly(font: .callout)
                CashlyText(template.cadence.rawValue.capitalized)
                    .cashly(font: .caption)
                    .cashly(color: .textSecondary)
            }
            CashlySpacer()
            CashlyText(CashlyCurrency.format(template.amount))
                .cashly(font: .callout, weight: .semibold)
        }
    }

    @MainActor
    private func reload() async {
        if let result = try? await recurringTransactions.templates() {
            templates = result
        }
    }

    @MainActor
    private func delete(_ template: RecurringTransactionTemplate) async {
        try? await recurringTransactions.remove(id: template.id)
        await reload()
    }

    public static var mock: some View {
        ManageRecurringScreen()
    }
}

private struct AddRecurringSheet: View {
    @Environment(\.mainState) var state
    @Environment(\.dismiss) var dismiss

    let onAdd: (RecurringTransactionTemplate) -> Void

    @State private var summary: String = ""
    @State private var amount: Double = 0
    @State private var selectedCategoryId: String = ""
    @State private var cadence: RecurringCadence = .monthly
    @State private var kind: TransactionKind = .expense
    @State private var startDate: Date = .now

    var body: some View {
        NavigationStack {
            Form {
                Section(CashlyL10n.string("Summary")) {
                    TextField("", text: $summary)
                }
                Section(CashlyL10n.string("Amount")) {
                    TextField("", value: $amount, format: .number)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                Section(CashlyL10n.string("Type")) {
                    Picker(selection: $kind) {
                        ForEach(TransactionKind.allCases, id: \.self) { k in
                            Text(verbatim: k.localizedSummary).tag(k)
                        }
                    } label: {
                        Text(CashlyL10n.string("Type"))
                    }
                }
                Section(CashlyL10n.string("Cadence")) {
                    Picker(selection: $cadence) {
                        ForEach(RecurringCadence.allCases, id: \.self) { c in
                            Text(verbatim: c.rawValue.capitalized).tag(c)
                        }
                    } label: {
                        Text(CashlyL10n.string("Cadence"))
                    }
                }
                Section(CashlyL10n.string("Category")) {
                    Picker(selection: $selectedCategoryId) {
                        ForEach(state.categories, id: \.id) { category in
                            Text(verbatim: category.name).tag(category.id)
                        }
                    } label: {
                        Text(CashlyL10n.string("Category"))
                    }
                }
                Section(CashlyL10n.string("Start")) {
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                }
            }
            .navigationTitle(CashlyL10n.string("New recurring"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CashlyL10n.string("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(CashlyL10n.string("Add")) {
                        let budgetId = state.budgets.first(where: {
                            $0.category.id == selectedCategoryId
                        })?.id ?? ""
                        onAdd(RecurringTransactionTemplate(
                            summary: summary,
                            amount: amount,
                            budgetId: budgetId,
                            categoryId: selectedCategoryId,
                            startDate: startDate.timeIntervalSince1970,
                            cadence: cadence,
                            kind: kind
                        ))
                        dismiss()
                    }
                    .disabled(summary.isEmpty || amount <= 0 || selectedCategoryId.isEmpty)
                }
            }
            .onAppear {
                if selectedCategoryId.isEmpty {
                    selectedCategoryId = state.categories.first?.id ?? ""
                }
            }
        }
    }
}
