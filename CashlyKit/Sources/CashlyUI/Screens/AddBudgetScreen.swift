import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import CashlyResource
import Foundation
import SwiftUI

public struct AddBudgetScreen: View {
    @State private var viewModel: BudgetViewModel

    var state: BudgetDraft { viewModel.draft }
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section
    @Environment(IntelligenceViewModel.self) var intelligence
    @Environment(MainViewModel.self) var main
    @Environment(\.user) var user

    @State var predictionInput: CashlyPredictionInput = .empty
    @State var predictionResult: CashlyPredictionResult = .empty

    public init(draft: BudgetDraft, factory: CashlyPresentationFactory) {
        _viewModel = State(initialValue: factory.makeBudgetViewModel(draft: draft))
    }

    public var body: some View {
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
        .onChange(of: state.yearMonth) { predictionInput = .empty }
        .onChange(of: predictionResult) { handlerPrediction() }
        .task(id: main.allCategories) { await viewModel.loadOrRefreshOptions() }
        .cashlyIntelligence(
            model: .budgetValue,
            input: $predictionInput,
            result: $predictionResult
        )
        .cashlyDismiss(isSaved: viewModel.isSaved)
        .cashlyErrorAlert(error: Binding(get: { viewModel.error }, set: { viewModel.error = $0 }))
        .disabled(viewModel.isLoading || viewModel.isSaved)
        .interactiveDismissDisabled(viewModel.isLoading)
        .environment(\.isLoading, viewModel.isLoading)
    }

    func handlerPrediction() {
        switch predictionResult {
        case .tabularRegression(let value):
            viewModel.draft.amount = value
        default:
            break
        }
    }

    @ViewBuilder
    var amountSection: some View {
        @Bindable var viewModel = viewModel
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

                CashlyCurrencyTextField(amount: $viewModel.draft.amount)
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
        @Bindable var viewModel = viewModel
        Section {
            TextField(
                "Provide a summary of your budget",
                text: $viewModel.draft.summary,
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
            viewModel.draft.category = category
        } label: {
            CashlySymbol(category.icon)
                .cashly(font: .system(size: 20))
                .cashly(
                    color: viewModel.draft.category == category
                        ? .hex(category.color) : .color(.secondary)
                )
                .frame(width: 45, height: 45)
                .cashly(
                    background: .color(
                        (viewModel.draft.category == category
                            ? Color(hex: category.color) : .secondary)
                            .opacity(0.2))
                )
                .cashly(clip: .circle)
                .overlay {
                    Circle()
                        .stroke(
                            viewModel.draft.category == category
                                ? Color(hex: category.color) : .secondary,
                            lineWidth: 3
                        )
                        .frame(width: 50, height: 50)
                }
                .opacity(viewModel.draft.category == category ? 1 : 0.3)
        }
        .buttonStyle(.plain)
        .cashlyPadding()
    }

    @ViewBuilder
    var dateSection: some View {
        @Bindable var viewModel = viewModel
        Section {
            DatePicker(
                "",
                selection: $viewModel.draft.date,
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
            Task { await viewModel.save() }
        } label: {
            CashlySymbol("checkmark")
        }
        .cashlyProminentButton()
        .accessibilityLabel("Salvar")
        .disabled(!viewModel.canSave)
        .cashly(tint: state.canSave ? .primary : .disabled)
    }

    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !viewModel.isLoading {
            Button {
                Task { await viewModel.remove() }
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
                    yearMonth: state.date.timeIntervalSince1970.yearMonth,
                    categoryID: state.category?.id ?? ""
                )
            } label: {
                CashlySymbol("bolt.fill")
            }
            .cashly(tint: .color(.yellow))
        }
    }

}
