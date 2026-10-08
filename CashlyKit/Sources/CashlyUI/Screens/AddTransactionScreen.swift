import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import CashlyResource
import Foundation
import SwiftUI

public struct AddTransactionScreen: View {
    @State private var viewModel: TransactionViewModel

    var state: TransactionDraft { viewModel.draft }
    @Environment(MainViewModel.self) var mainState
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section
    @Environment(IntelligenceViewModel.self) var intelligence
    @Environment(\.user) var user

    @State var isActivePrediction: Bool = true
    @State var predictionResult: CashlyPredictionResult = .empty

    var predictionInput: Binding<CashlyPredictionInput> {
        Binding {
            state.summary.isEmpty ? .empty : .text(state.summary)
        } set: { _ in
        }
    }

    public init(draft: TransactionDraft, factory: CashlyPresentationFactory) {
        _viewModel = State(initialValue: factory.makeTransactionViewModel(draft: draft))
        _isActivePrediction = State(initialValue: draft.isNew)
    }

    public var body: some View {
        Form {
            amountSection
            summarySection
            if let budget = mainState.budgets.first(where: {
                $0.category.id == state.category?.id
                    && $0.date == state.date.timeIntervalSince1970.yearMonth
            }), budget.isConflicted {
                Section {
                    Button("Resolver conflito de orçamento") {
                        open(
                            .budgetConflict(categoryID: budget.category.id, month: budget.date),
                            in: section)
                    }
                }
            }
            tagsSection
            categoriesSection
            dateSection
            installmentSection
            selectedParticipantsSection
        }
        .toolbar {
            ToolbarItemGroup {
                intelligenceItem
                participantsItem
                removeButton
            }

            ToolbarItem { saveButton }
        }
        .task(id: CatalogRequest(categories: mainState.allCategories, tags: mainState.allTags)) {
            await viewModel.loadOrRefreshOptions()
        }
        .onChange(of: state.participants) { updateSplitValue() }
        .onChange(of: state.amount) { updateSplitValue() }
        .onChange(of: state.splitMode) { viewModel.changeSplitMode() }
        .onChange(of: predictionResult) { handlerPrediction() }

        .cashlyDismissKeyboardOnScroll()
        .cashlyIntelligence(
            model: .categoryName,
            isActive: isActivePrediction && state.kind == .expense,
            input: predictionInput,
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
        case .textClassification(let value):
            let categoryID = value
            viewModel.draft.category =
                state.categories.first { $0.id == categoryID } ?? state.category
        default:
            break
        }
    }

    @ViewBuilder
    var amountSection: some View {
        @Bindable var viewModel = viewModel
        Section {
        } header: {
            CashlyVStack(spacing: .small) {
                transactionStatusView
                splitValueView

                CashlyVStack(spacing: .zero) {
                    CashlyCurrencyTextField(amount: $viewModel.draft.amount)
                        #if os(iOS)
                            .keyboardType(.decimalPad)
                        #endif
                        .cashly(alignment: .center)
                        .cashly(font: .system(size: 40), weight: .black)
                        .cashly(tint: .color(.clear))

                    if state.installmentIsOn, state.amount > .zero {
                        let money = (try? Money(validating: state.amount)) ?? .zero
                        let first = money.installment(at: 0, count: state.installmentPlan)
                        let last = money.installment(
                            at: state.installmentPlan - 1, count: state.installmentPlan)
                        let description =
                            first == last
                            ? "\(state.installmentPlan)x de \(first.formatted)"
                            : "\(state.installmentPlan)x de \(last.formatted) a \(first.formatted)"
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

    @ViewBuilder
    var transactionStatusView: some View {
        @Bindable var viewModel = viewModel
        Menu {
            Picker(selection: $viewModel.draft.status) {
                ForEach(TransactionStatus.allCases) {
                    CashlyText($0.summary)
                        .tag($0)
                }
            } label: {
                EmptyView()
            }
        } label: {
            CashlyText(state.status.summary.uppercased())
                .cashly(font: .caption, weight: .bold)
                .cashly(color: .color(state.status.color))
                .cashlyPadding()
                .cashlyPadding(.horizontal, .extraSmall)
                .cashlySurface(
                    tint: state.status.color.opacity(0.2), in: .capsule, interactive: true)
        }
    }

    @ViewBuilder
    var splitValueView: some View {
        let status = state.participants.first(where: { $0.status != .settled })?.status ?? .settled
        if !state.participants.isEmpty {
            CashlyText(state.splitValue?.currency())
                .cashly(font: .headline, weight: .semibold)
                .cashly(color: .color(status.color))
                .contentTransition(.numericText())
                .animation(.linear, value: state.splitValue)
                .cashlyPadding()
                .cashlyPadding(.horizontal, .extraSmall)
                .cashlyContentSurface(tint: status.color.opacity(0.2), in: .capsule)
        }
    }

    @ViewBuilder
    var summarySection: some View {
        @Bindable var viewModel = viewModel
        Section {
            TextField(
                "Provide a summary of your transaction",
                text: $viewModel.draft.summary,
                axis: .vertical
            )
        } header: {
            CashlyText("Summary")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }

    @ViewBuilder
    var tagsSection: some View {
        @Bindable var viewModel = viewModel
        if !state.tags.isEmpty {
            Section("Tags") {
                ForEach(state.tags) { tag in
                    Toggle(
                        tag.name,
                        isOn: Binding(
                            get: { state.selectedTagIDs.contains(tag.id) },
                            set: { selected in
                                if selected {
                                    viewModel.draft.selectedTagIDs.insert(tag.id)
                                } else {
                                    viewModel.draft.selectedTagIDs.remove(tag.id)
                                }
                            }))
                }
                if !state.suggestedTags.isEmpty {
                    Text("Sugestões pela descrição").font(.caption).foregroundStyle(.secondary)
                    ForEach(state.suggestedTags) { tag in
                        Button("Adicionar \(tag.name)") {
                            viewModel.draft.selectedTagIDs.insert(tag.id)
                        }
                    }
                }
            }
        }
    }

    var categoriesSection: some View {
        Section {
            categoriesView
            EmptyCategoryView()
            EmptyBudgetView(budgets: mainState.budgets)
        } header: {
            CashlyHStack {
                CashlyText("Categories")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
                Spacer()
                CategoryVariationView(
                    category: state.category,
                    amount: state.amount
                )
            }
        } footer: {
            if let category = state.category {
                let remaining = mainState.categoryRemainingAmount(category: category) - state.amount
                let description =
                    remaining < .zero
                    ? "You’ve exceeded the planned budget in the \(category.name.capitalized) category by \((remaining * -1).currency() ?? "")"
                    : "You’re \(remaining.currency() ?? "") away from reaching the planned budget in the \(category.name.capitalized) category."
                CashlyText(description)
                    .contentTransition(.numericText(value: remaining))
                    .animation(.bouncy, value: state.amount)
            }
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
                .task(id: state.category) {
                    do {
                        try await Task.sleep(for: .milliseconds(200))
                        try Task.checkCancellation()
                        withAnimation(.bouncy.speed(0.5)) {
                            proxy.scrollTo(state.category, anchor: .center)
                        }
                    } catch {}
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    func categoryItemView(category: CashlyDomain.Category) -> some View {
        Button {
            isActivePrediction = false
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
                state.date.string(with: .cashly(.weekDay)) ?? "",
                selection: $viewModel.draft.date,
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

    @ViewBuilder
    var splitModeView: some View {
        @Bindable var viewModel = viewModel
        CashlyHStack {
            CashlyText("Select Split Mode")

            Spacer()

            Menu {
                Picker(selection: $viewModel.draft.splitMode) {
                    ForEach(TransactionSplitMode.allCases) {
                        CashlyText($0.summary)
                            .tag(Optional($0))
                    }
                } label: {
                    EmptyView()
                }
            } label: {
                CashlyText(state.splitMode?.summary.uppercased())
                    .cashly(font: .caption, weight: .semibold)
                    .cashly(color: .primary)
                    .cashlyPadding()
                    .cashlyPadding(.horizontal, .extraSmall)
                    .cashlySurface(tint: .accentColor.opacity(0.2), in: .capsule, interactive: true)
            }
        }
    }

    func participantBinding(id: String) -> Binding<Participant> {
        Binding(
            get: { state.participants.first { $0.id == id } ?? .empty },
            set: { participant in
                guard let index = viewModel.draft.participants.firstIndex(where: { $0.id == id })
                else {
                    return
                }
                viewModel.draft.participants[index] = participant
            })
    }
    var participantsView: some View {
        Section {
            ForEach(state.participants) { participant in
                ParticipantRowView(
                    participant: participantBinding(id: participant.id), amount: state.amount
                )
                .swipeActions {
                    Button(role: .destructive) {
                        viewModel.selectParticipants(
                            Set(state.participants.filter { $0.id != participant.id }.map(\.user)))
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
    func updateSplitValue() {
        viewModel.updateShares()
    }

    @ViewBuilder
    var participantsItem: some View {
        let users = mainState.users.filter { $0.id != mainState.user?.id }
        if !users.isEmpty {
            CashlyMenuSelectionView(
                items: users,
                selectedItems: Binding(
                    get: { Set(state.participants.map(\.user)) },
                    set: { viewModel.selectParticipants($0) })
            ) { user in
                CashlyText(user.name.capitalized)
            } label: {
                CashlySymbol("person.2.badge.plus.fill")
                    .cashly(color: .text)
            }
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
    var installmentSection: some View {
        @Bindable var viewModel = viewModel
        Section {
            Toggle(isOn: $viewModel.draft.installmentIsOn) {
                CashlyText("Enable installments")
            }

            if state.installmentIsOn {
                Picker(selection: $viewModel.draft.installmentPlan) {
                    ForEach(1...21, id: \.self) {
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

    @ViewBuilder
    var intelligenceItem: some View {
        if user != nil,
            intelligence.hasModel(.categoryName),
            !isActivePrediction
        {
            Button {
                isActivePrediction = true
            } label: {
                CashlySymbol("bolt.fill")
            }
        }
    }

}

private struct CatalogRequest: Hashable {
    let categories: [CashlyDomain.Category]
    let tags: [Tag]
}
