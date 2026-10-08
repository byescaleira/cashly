import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import CashlyResource
import Foundation
import SwiftUI

public struct TransactionScreen: View {

    @Environment(MainViewModel.self) var state
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    @State private var isSelecting = false
    @State private var selection: Set<CashlyDomain.Transaction> = []

    public init() {}

    public var body: some View {
        List(selection: $selection) {
            TransactionBalanceView()
            EmptyCategoryView()
            EmptyBudgetView(budgets: state.budgets)
            EmptyUserView()
            DataStatusView()
            transactionsSection
            if state.hasMoreTransactions {
                Button("Carregar mais transações") { Task { await state.loadMoreTransactions() } }
                    .disabled(state.isLoading || state.isLoadingMore)
            }
            if state.isLoadingMore { ProgressView() }

        }
        #if os(iOS) || os(visionOS)
            .environment(
                \.editMode,
                Binding(
                    get: { isSelecting ? .active : .inactive }, set: { isSelecting = $0 == .active }
                ))
        #endif
        .toolbar {
            ToolbarItem(placement: .navigation) {
                if !isSelecting {
                    UserItemView()
                }
                selectAllButton
            }

            ToolbarItemGroup {
                editButton
                FilterItemView()
            }

            CashlyToolbarSpacer()
            ToolbarItemGroup {
                addButton

                shareButton
                removeButton
                checkButton
            }
        }
        .environment(\.isLoading, state.isLoading)
        .refreshable { await state.load() }
        .navigationTitle("Transactions")
        .onChange(of: state.transactions) {
            let ids = Set(selection.map(\.id))
            selection = Set(state.transactions.filter { ids.contains($0.id) })
        }
        .onChange(of: state.user?.id) {
            selection = []
            isSelecting = false
        }
    }

    @ViewBuilder
    var transactionsSection: some View {
        let sections = state.transactionSections
        ForEach(sections.indices, id: \.self) {
            let transactions = sections[$0]
            let sectionDate = transactions.first.map { transaction in
                state.filter.isFilteringByDate
                    ? transaction.billingDate(
                        in: state.filter.startDate.timeIntervalSince1970.yearMonth)
                        ?? transaction.date.date : transaction.date.date
            }
            Section {
                ForEach(transactions) { transaction in
                    Button {
                        open(.addTransaction(id: transaction.id), in: section)
                    } label: {
                        transactionView(transaction: transaction)
                    }
                    .tag(transaction)
                    .cashly(tint: .text)
                    .cashlyDelete { Task { await state.removeTransaction(transaction) } }
                }
            } header: {
                CashlyHStack {
                    CashlyText(sectionDate?.cashly(with: .transactionSection))
                    Spacer()
                    CashlyText(sectionDate?.cashly(with: .weekDay))
                }
                .textCase(.uppercase)
                .cashly(font: .footnote)
                .cashly(color: .textSecondary)
            }
        }
    }

    func transactionView(transaction: CashlyDomain.Transaction) -> some View {
        CashlyHStack(spacing: .medium) {
            categoryIcon(category: transaction.category)
                .overlay(alignment: .bottomTrailing) {
                    statusView(
                        participants: transaction.participants,
                        status: transaction.status
                    )
                }

            CashlyVStack(alignment: .leading, spacing: .extraSmall) {
                CashlyText(transaction.summary)

                CashlyHStack {
                    CashlyText(transaction.date.date.cashly(with: .time))
                    participantsView(participants: transaction.participants)
                }
                .cashly(color: .textSecondary)
            }
            .cashly(font: .callout)

            Spacer()

            CashlyVStack(alignment: .trailing, spacing: .extraSmall) {
                if !transaction.participants.isEmpty {
                    CashlyText(
                        transaction.billingMoney(
                            in: state.filter.isFilteringByDate
                                ? state.filter.startDate.timeIntervalSince1970.yearMonth : nil
                        ).formatted)
                } else if let paymentPlan = transaction.paymentsPlan {
                    CashlyHStack(spacing: .extraSmall) {
                        CashlyText(paymentPlan.string + "x")
                            .cashly(color: .textSecondary)
                        CashlyText(
                            transaction.billingMoney(
                                in: state.filter.isFilteringByDate
                                    ? state.filter.startDate.timeIntervalSince1970.yearMonth : nil
                            ).formatted)
                    }
                }

                CashlyText(transaction.money.formatted)
                    .cashly(
                        color: transaction.participants.isEmpty && transaction.paymentsPlan == nil
                            ? .text : .textSecondary)
            }
            .cashly(font: .callout, weight: .semibold)

            CashlySymbol("chevron.forward")
                .cashly(color: .disabled)
        }
        .lineLimit(2)
    }

    func categoryIcon(category: CashlyDomain.Category) -> some View {
        CashlySymbol(category.icon)
            .cashly(font: .system(size: 18))
            .cashly(color: .hex(category.color))
            .frame(width: 40, height: 40)
            .cashly(background: .color((Color(hex: category.color)).opacity(0.2)))
            .cashly(clip: .circle)
    }

    @ViewBuilder
    func statusView(
        participants: [Participant],
        status: TransactionStatus
    ) -> some View {
        if status != .settled {
            CashlySymbol(status.icon)
                .cashly(font: .system(size: 10), weight: .bold)
                .cashly(color: .white)
                .cashlyPadding(.extraSmall)
                .cashlyContentSurface(tint: status.color, in: .circle)
                .cashlyPadding([.bottom, .trailing], .negative(.extraSmall))
        }
    }

    @ViewBuilder
    func participantsView(participants: [Participant]) -> some View {
        if !participants.isEmpty {
            CashlyHStack(spacing: .zero) {
                ForEach(participants.indices, id: \.self) { index in
                    let participant = participants[index]
                    Circle()
                        .fill(participant.status.color)
                        .frame(width: 10, height: 10)
                        .padding(.trailing, 2)
                }
            }
        }
    }

    @ViewBuilder
    var addButton: some View {
        if !state.users.isEmpty, !isSelecting {
            Button {
                open(.addTransaction(id: nil), in: section)
            } label: {
                CashlySymbol("plus")
                    .cashly(color: .text)
            }
            .disabled(state.isLoading)
        }
    }

    @ViewBuilder
    var editButton: some View {
        if !state.users.isEmpty, !isSelecting, !state.transactions.isEmpty {
            Button {
                withAnimation(.bouncy(duration: 0.8)) {
                    isSelecting = true
                }
            } label: {
                CashlySymbol("checkmark.circle")
                    .cashly(color: .text)
            }
            .disabled(state.isLoading)
        }
    }

    @ViewBuilder
    var selectAllButton: some View {
        let isAllSelected = selection.count == state.transactions.count
        if isSelecting {
            Button {
                selection = isAllSelected ? [] : Set(state.transactions)
            } label: {
                CashlyText(isAllSelected ? "Clear Selection" : "Selecionar transações carregadas")
                    .cashly(font: .body, weight: .bold)
                    .cashly(color: .text)
            }
            .disabled(state.isLoading)
        }
    }

    @ViewBuilder
    var shareButton: some View {
        if isSelecting {
            ShareLink(
                item: selection.shareMessage(
                    participants: state.filter.participants,
                    billingMonth: state.filter.isFilteringByDate
                        ? state.filter.startDate.timeIntervalSince1970.yearMonth : nil)
            ) {
                CashlySymbol("square.and.arrow.up")
                    .cashly(color: selection.isEmpty ? .disabled : .text)
            }
            .disabled(state.isLoading)
            .disabled(selection.isEmpty)
        }
    }

    @State var showDeleteAlert = false

    @ViewBuilder
    var removeButton: some View {
        if isSelecting {
            Button {
                showDeleteAlert = true
            } label: {
                CashlySymbol("trash")
                    .cashly(color: selection.isEmpty ? .disabled : .text)
            }
            .disabled(state.isLoading)
            .disabled(selection.isEmpty)
            .alert("Delete Transactions", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task { await state.removeTransactions(selection) }
                }
            } message: {
                CashlyText(
                    "Are you sure you want to delete \(selection.count) selected transaction\(selection.count == 1 ? "" : "s")? This action cannot be undone."
                )
            }

        }
    }

    @ViewBuilder
    var checkButton: some View {
        if isSelecting {
            Button {
                withAnimation(.bouncy(duration: 0.8)) {
                    isSelecting = false
                }
            } label: {
                CashlySymbol("checkmark")
            }
            .disabled(state.isLoading)
            .cashlyProminentButton()
        }
    }

}
