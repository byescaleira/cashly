//
//  AddTransactionScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 04/09/25.
//

import SwiftUI
import CashlyMock
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct AddTransactionScreen: CashlyView {
    @EnvironmentObject var store: CashlyStore<AddTransactionReducer, AddTransactionMiddleware>
    
    @Environment(\.addTransactionState) var state
    @Environment(\.mainState) var mainState
    @Environment(\.action) var action
    
    @State var selectedUsers: Set<User> = []
    
    public init() {}
    
    public var body: some View {
        Form {
            amountSection
            selectedParticipantsSection
            dateSection
            categoriesSection
            summarySection
        }
        .toolbar {
            ToolbarItem(placement: .navigation) { participantsItem }
            ToolbarItem { saveButton }
            ToolbarItem { removeButton }
        }
        .task { action(.addTransaction(.fetch)) }
        .onChange(of: state.date.timeIntervalSince1970.yearMonth) { action(.addTransaction(.fetch)) }
        .onChange(of: store.state.splitMode) { onChangeUsers() }
        .onChange(of: selectedUsers) { onChangeUsers() }
        .onChange(of: state.participants) { updateSplitValue() }
        .environment(\.isLoading, state.isLoading)
    }
    
    func onChangeUsers() {
        guard !selectedUsers.isEmpty else {
            store.state.splitMode = nil
            store.state.splitValue = nil
            return
        }
        store.state.splitMode = state.splitMode ?? .equal
        let participants = selectedUsers.map {
            let splitValue: Double
            switch store.state.splitMode ?? .equal {
            case .equal: splitValue = (selectedUsers.count.double + 1)
            case .fixedAmount: splitValue = .zero
            case .percentage: splitValue = 1 / (selectedUsers.count.double + 1)
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
        store.state.splitValue = state.amount - participants.compactMap {
            let value = $0.splitMode.value(splitValue: $0.splitValue, amount: state.amount)
            return value
        }.reduce(.zero, +)
        store.state.participants = participants
    }
    
    func updateSplitValue() {
        store.state.splitValue = state.amount - store.state.participants.compactMap {
            let value = $0.splitMode.value(splitValue: $0.splitValue, amount: state.amount)
            return value
        }.reduce(.zero, +)
    }
    
    var amountSection: some View {
        Section {} header: {
            CashlyVStack(spacing: .small) {
                transactionStatusView
                splitValueView
                
                CashlyCurrencyTextField(amount: $store.state.amount)
                    .cashly(alignment: .center)
                    .cashly(font: .system(size: 40), weight: .black)
                    .cashly(tint: .color(.clear))
            }
            .frame(maxWidth: .infinity)
            .cashlyPadding(.vertical, .negative(.small))
        }
    }
    
    @ViewBuilder
    var transactionStatusView: some View {
        if state.splitMode == nil {
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
        if state.splitMode != nil {
            CashlyText(state.splitValue?.currency())
                .cashly(font: .headline, weight: .semibold)
                .cashly(color: .primary)
                .contentTransition(.numericText())
                .cashlyPadding()
                .cashlyPadding(.horizontal, .extraSmall)
                .cashly(glass: .clear.tint(.accentColor.opacity(0.2)), in: .capsule)
                .animation(.linear, value: state.amount)
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
    
    var tagsView: some View {
        CashlyHorizontalList {
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
                }
            }
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, -40)
        .cashlyPadding(.top, .small)
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
            CashlyHorizontalList {
                CashlyHStack {
                    ForEach(state.categories) { category in
                        categoryItemView(category: category)
                    }
                }
                .cashlyPadding(.horizontal, .medium)
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
        if !selectedUsers.isEmpty {
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
    
    var participantsView: some View {
        Section {
            ForEach(store.state.participants.enumerated(), id: \.offset) { index, participant in
                ParticipantRowView(
                    participant: $store.state.participants[index],
                    amount: state.amount
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    CashlyButton(role: .destructive) {
                        if selectedUsers.contains(participant.user) {
                            selectedUsers.remove(participant.user)
                        }
                    } label: {
                        CashlyLabel("Delete", symbol: "trash.fill")
                    }
                    .cashly(tint: .error)
                }
            }
        }
    }
    
    @ViewBuilder
    var participantsItem: some View {
        if !mainState.users.isEmpty {
            CashlyMenuSelectionView(
                items: mainState.users,
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
