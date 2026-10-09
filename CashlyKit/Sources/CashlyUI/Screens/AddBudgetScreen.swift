import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import CashlyResource
import FeatureCore
import Foundation
import SwiftUI

public struct AddBudgetScreen: View {
    @Environment(BudgetEditorModel.self) private var model

    var state: BudgetDraft { model.draft }
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section
    @Environment(IntelligenceModel.self) var intelligence
    @Environment(FinanceModel.self) var finance
    @Environment(\.user) var user

    @State var predictionInput: CashlyPredictionInput = .empty
    @State var predictionResult: CashlyPredictionResult = .empty

    public init() {}

    public var body: some View {
        @Bindable var status = model.status
        Form {
            amountSection
            summarySection
            categoriesSection
            dateSection
        }
        .toolbar {
            ToolbarItemGroup {
                quickFillItem
                removeButton
            }

            ToolbarItem { saveButton }
        }
        .cashlyDismissKeyboardOnScroll()
        .onChange(of: state.category?.id) { predictionInput = .empty }
        .onChange(of: state.month) { predictionInput = .empty }
        .onChange(of: predictionResult) { handlerPrediction() }
        .task(id: finance.allCategories) { await model.loadOrRefresh() }
        .cashlyIntelligence(
            model: .budgetValue,
            input: $predictionInput,
            result: $predictionResult
        )
        .cashlyDismiss(isSaved: model.status.isSaved)
        .cashlyErrorAlert(error: $status.error)
        .disabled(model.status.isBusy || model.status.isSaved)
        .interactiveDismissDisabled(model.status.isBusy)
        .environment(\.isLoading, model.status.isBusy)
    }

    func handlerPrediction() {
        switch predictionResult {
        case .tabularRegression(let value):
            model.draft.amount = value
        default:
            break
        }
    }

    @ViewBuilder
    var amountSection: some View {
        @Bindable var model = model
        Section {
        } header: {
            CashlyVStack(spacing: .zero) {
                CashlyText(state.category?.name.uppercased())
                    .cashly(font: .caption, weight: .bold)
                    .cashly(color: .hex(state.category?.color))
                    .cashlyPadding()
                    .cashlyPadding(.horizontal, .extraSmall)
                    .cashlyContentSurface(
                        tint: Color(hex: state.category?.color).opacity(0.2), in: .capsule)

                CashlyCurrencyTextField(amount: $model.draft.amount)
                    #if os(iOS)
                        .keyboardType(.decimalPad)
                    #endif
                    .frame(maxWidth: .infinity)
                    .cashly(alignment: .center)
                    .cashly(font: .system(size: 40), weight: .black)
                    .cashlyPadding(.top, .medium)
                    .cashly(tint: .color(.clear))
            }
        }
    }

    @ViewBuilder
    var summarySection: some View {
        @Bindable var model = model
        Section {
            TextField(
                "Provide a summary of your budget",
                text: $model.draft.summary,
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
            EmptyCategoriesSection()
        } header: {
            CashlyText("Categories")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }

    @ViewBuilder
    var categoriesView: some View {
        if !state.categories.isEmpty {
            CashlyHorizontalList { proxy in
                CashlyHStack {
                    ForEach(state.categories) { category in
                        categoryItemView(category: category)
                            .id(category)
                    }
                }
                .cashlyPadding(.horizontal, .medium)
                .onChange(of: state.category) {
                    withAnimation(.bouncy) {
                        proxy.scrollTo(state.category, anchor: .center)
                    }
                }
            }
            .cashlyPadding(.horizontal, .negative(.medium))
        }
    }

    func categoryItemView(category: CashlyDomain.Category) -> some View {
        Button {
            model.draft.category = category
        } label: {
            CashlySymbol(category.icon)
                .cashly(font: .system(size: 20))
                .cashly(
                    color: model.draft.category == category
                        ? .hex(category.color) : .color(.secondary)
                )
                .frame(width: 45, height: 45)
                .cashly(
                    background: .color(
                        (model.draft.category == category
                            ? Color(hex: category.color) : .secondary)
                            .opacity(0.2))
                )
                .cashly(clip: .circle)
                .overlay {
                    Circle()
                        .stroke(
                            model.draft.category == category
                                ? Color(hex: category.color) : .secondary,
                            lineWidth: 3
                        )
                        .frame(width: 50, height: 50)
                }
                .opacity(model.draft.category == category ? 1 : 0.3)
        }
        .buttonStyle(.plain)
        .cashlyPadding()
    }

    @ViewBuilder
    var dateSection: some View {
        @Bindable var model = model
        Section {
            DatePicker(
                "",
                selection: $model.draft.date,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .cashlyPadding(.vertical, .negative(.medium))
            .cashly(tint: .primary)
        } header: {
            CashlyText("Date")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }

    var saveButton: some View {
        Button {
            Task { await model.save() }
        } label: {
            CashlySymbol("checkmark")
        }
        .cashlyProminentButton()
        .accessibilityLabel("Salvar")
        .disabled(!model.canSave)
        .cashly(tint: state.canSave ? .primary : .disabled)
    }

    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !model.status.isBusy {
            Button {
                Task { await model.remove() }
            } label: {
                CashlySymbol("trash")
            }
            .cashly(tint: .text)
        }
    }

    @ViewBuilder
    var quickFillItem: some View {
        if user != nil,
            intelligence.hasModel(.budgetValue)
        {
            Button {
                predictionInput = .budget(
                    month: state.month,
                    categoryID: state.category?.id ?? ""
                )
            } label: {
                CashlySymbol("bolt.fill")
            }
            .cashly(tint: .color(.yellow))
        }
    }

}
