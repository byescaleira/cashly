//
//  AddTransactionScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 04/09/25.
//

import SwiftUI
import RyzeArchitecture
import CashlyMock
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct AddTransactionScreen: CashlyView {
    @EnvironmentObject var store: CashlyStore<AddTransactionReducer, AddTransactionMiddleware>
    
    @Environment(\.addTransactionState) var state
    @Environment(\.mainState) var mainState
    @Environment(\.action) var action
    @Environment(\.router) var router
    
    @State var selectedUsers: Set<User> = []
    
    var initialState: AddTransactionState?
    
    public init(initialState: AddTransactionState? = nil) {
        self.initialState = initialState
    }
    
    public var body: some View {
        Form {
            amountSection
            selectedParticipantsSection
            dateSection
            summarySection
            categoriesSection
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                participantsItem
                CashlySpacer()
                saveButton
                removeButton
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .task { await handlerInitialState() }
        .onChange(of: state.date.timeIntervalSince1970.yearMonth) { action(.addTransaction(.fetch)) }
        .onChange(of: selectedUsers) { onChangeSelectedUsers() }
        .onChange(of: state.participants.count) { updateSplitValue() }
        .onChange(of: state.amount) { updateSplitValue() }
        .onDisappear { selectedUsers = [] }
        .scrollDismissesKeyboard(.immediately)
        .cashlyDismiss(isSaved: state.isSaved)
        .environment(\.isLoading, state.isLoading)
    }
    
    func handlerInitialState() async {
        if let initialState {
            store.state = initialState
        }
        try? await Task.sleep(for: .seconds(0.5))
        action(.addTransaction(.fetch))
    }
    
    func onChangeSelectedUsers() {
        store.state.splitMode = selectedUsers.isEmpty ? nil : store.state.splitMode ?? .equal
        store.state.participants = selectedUsers.map {
            let splitValue: Double
            switch store.state.splitMode ?? .equal {
            case .equal: splitValue = (selectedUsers.count.double + 1)
            case .fixedAmount: splitValue =  .zero
            case .percentage: splitValue =  1 / (selectedUsers.count.double + 1)
            case .payerBased: splitValue = .zero
            }
            return Participant(
                id: UUID().uuidString,
                user: $0,
                splitMode: store.state.splitMode ?? .equal,
                splitValue: splitValue,
                status: .settled,
                transaction: state.id
            )
        }.sorted(by: \.user.name)
    }
    
    var amountSection: some View {
        Section {} header: {
            CashlyVStack(spacing: .small) {
                transactionStatusView
                splitValueView
                
                CashlyCurrencyTextField(amount: $store.state.amount)
                    .keyboardType(.numberPad)
                    .cashly(alignment: .center)
                    .cashly(font: .system(size: 40), weight: .black)
                    .cashly(tint: .color(.clear))
            }
            .frame(maxWidth: .infinity)
            .cashlyPadding(.vertical, .small)
        }
    }
    
    @ViewBuilder
    var transactionStatusView: some View {
        if state.participants.isEmpty {
            Menu {
                Picker(selection: $store.state.status) {
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
                    .cashly(glass: .clear.tint(state.status.color.opacity(0.2)).interactive(), in: .capsule)
            }
        }
    }
    
    @ViewBuilder
    var splitValueView: some View {
        if !state.participants.isEmpty {
            CashlyText(state.splitValue?.currency())
                .cashly(font: .headline, weight: .semibold)
                .cashly(color: .primary)
                .contentTransition(.numericText())
                .animation(.linear, value: store.state.splitValue)
                .cashlyPadding()
                .cashlyPadding(.horizontal, .extraSmall)
                .cashly(glass: .clear.tint(.accentColor.opacity(0.2)), in: .capsule)
        }
    }
    
    var summarySection: some View {
        Section {
            TextField(
                "Provide a summary of your transaction",
                text: $store.state.summary,
                axis: .vertical
            )
        } header: {
            CashlyText("Summary")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        } footer: {
            tagsView
        }
    }
    
    @ViewBuilder
    var tagsView: some View {
        CashlyZStack {
            if !state.summaryTags.isEmpty {
                CashlyHorizontalList { _ in
                    CashlyHStack {
                        ForEach(state.summaryTags) { tag in
                            CashlyHStack {
                                CashlySymbol(tag.icon)
                                CashlyText(tag.name.uppercased())
                            }
                            .cashly(font: .footnote, weight: .semibold)
                            .cashly(color: .hex(tag.color))
                            .cashlyPadding()
                            .cashlyPadding(.horizontal, .extraSmall)
                            .cashly(
                                glass: .clear.tint(Color(hex: tag.color).opacity(0.2)),
                                in: .capsule
                            )
                            .transition(.move(edge: .top).animation(.bouncy.speed(0.2)))
                        }
                    }
                    .padding(.horizontal, 30)
                }
                .frame(height: 50)
                .padding(.horizontal, -40)
            }
        }
        .animation(.bouncy, value: state.summaryTags)
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
        CashlyButton {
            store.state.budget = state.budgets.first(where: { $0.category.id == category.id })
        } label: {
            CashlySymbol(category.icon)
                .cashly(font: .system(size: 20))
                .cashly(color: state.category == category ? .hex(category.color) : .color(.secondary))
                .frame(width: 45, height: 45)
                .cashly(background: .color((state.category == category ? Color(hex: category.color) : .secondary).opacity(0.2)))
                .cashly(clip: .circle)
                .overlay {
                    Circle()
                        .stroke(state.category == category ? Color(hex: category.color) : .secondary, lineWidth: 3)
                        .frame(width: 50, height: 50)
                }
                .opacity(state.category == category ? 1 : 0.3)
        }
        .buttonStyle(.plain)
        .cashlyPadding()
    }
    
    var dateSection: some View {
        Section {
            DatePicker(
                state.date.string(with: CashlyDateFormatter.weekDay) ?? "",
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
    
    var splitModeView: some View {
        CashlyHStack {
            CashlyText("Select Split Mode")
            
            CashlySpacer()
            
            Menu {
                Picker(selection: $store.state.splitMode) {
                    ForEach(TransactionSplitMode.allCases) {
                        CashlyText($0.summary)
                            .tag($0)
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
                    .cashly(glass: .clear.tint(.accentColor.opacity(0.2)), in: .capsule)
            }
        }
    }
    
    func participantBinding(at index: Int) -> Binding<Participant> {
        Binding {
            guard store.state.participants.indices.contains(index) else { return .empty }
            return store.state.participants[index]
        } set: { participant in
            guard store.state.participants.indices.contains(index) else { return }
            store.state.participants[index] = participant
        }
    }
    
    var participantsView: some View {
        Section {
            ForEach(Array(store.state.participants).enumerated(), id: \.offset) { index, participant in
                ParticipantRowView(
                    participant: participantBinding(at: index),
                    splitMode: state.splitMode,
                    amount: state.amount,
                    count: state.participants.count
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    CashlyButton(role: .destructive) {
                        if let index = state.participants.firstIndex(of: participant) {
                            store.state.participants.remove(at: index)
                        }
                    } label: {
                        CashlyLabel("Delete", symbol: "trash.fill")
                    }
                    .cashly(tint: .error)
                }
                .onChange(of: participant.splitValue) { updateSplitValue() }
            }
        }
    }
    
    func updateSplitValue() {
        store.state.splitValue = store.state.participants.isEmpty ? nil : (store.state.amount - store.state.participants.compactMap {
            let value = $0.splitMode.value(splitValue: $0.splitValue, amount: store.state.amount)
            return value
        }.reduce(.zero, +))
    }

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
            }
        }
    }
    
    var saveButton: some View {
        CashlyButton {
            action(.addTransaction(.save))
        } label: {
            CashlySymbol("checkmark")
                .cashly(font: .headline, weight: .bold)
        }
        .disabled(!state.canSave)
        .cashly(tint: .primary)
    }
    
    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !state.isLoading {
            CashlyButton {
                action(.addTransaction(.remove))
            } label: {
                CashlySymbol("trash")
                    .cashly(font: .headline, weight: .bold)
            }
            .cashly(tint: .error)
        }
    }
    
    public static var mock: some View {
        AddTransactionScreen()
    }
}

#Preview {
    NavigationView {
        AddTransactionScreen
            .cashlyPreview()
    }
}
