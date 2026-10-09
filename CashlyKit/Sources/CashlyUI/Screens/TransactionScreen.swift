import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import CashlyResource
import FeatureCore
import Foundation
import SwiftUI

public struct TransactionScreen: View {

    @Environment(SessionModel.self) var session

    @Environment(FinanceModel.self) var finance

    @Environment(TransactionListModel.self) var transactions
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    @State private var isSelecting = false
    @State private var selection: Set<CashlyDomain.Transaction> = []

    public init() {}

    public var body: some View {
        List(selection: $selection) {
            TransactionBalanceView()
            EmptyCategoriesSection()
            EmptyBudgetsSection()
            EmptyUsersSection()
            DataStatusSection()
            transactionsSection
            if transactions.hasMore {
                Button("Carregar mais transações") { Task { await transactions.loadMore() } }
                    .disabled(finance.isLoading || transactions.isLoadingMore)
            }
            if transactions.isLoadingMore { ProgressView() }

        }
        #if os(iOS) || os(visionOS)
            .environment(
                \.editMode,
                Binding(
                    get: { isSelecting ? .active : .inactive }, set: { isSelecting = $0 == .active }
                ))
        #endif
        .toolbar {
            ToolbarItem(placement: .leading) {
                if !isSelecting {
                    UserMenu()
                }
                selectAllButton
            }

            ToolbarItemGroup {
                editButton
                FilterMenu()
            }

            CashlyToolbarSpacer()
            ToolbarItemGroup {
                addButton

                shareButton
                removeButton
                checkButton
            }
        }
        .environment(\.isLoading, finance.isLoading)
        .refreshable { await transactions.load() }
        .task(id: session.loadKey) { await transactions.load() }
        .navigationTitle("Transactions")
        .onChange(of: transactions.items) {
            let ids = Set(selection.map(\.id))
            selection = Set(transactions.items.filter { ids.contains($0.id) })
        }
        .onChange(of: session.user?.id) {
            selection = []
            isSelecting = false
        }
    }

    @ViewBuilder
    var transactionsSection: some View {
        let sections = transactions.sections
        ForEach(sections.indices, id: \.self) {
            let group = sections[$0]
            let sectionDate = group.first.map { transaction in
                session.filter.isFilteringByDate
                    ? transaction.billingDate(
                        in: YearMonth(session.filter.startDate))
                        ?? transaction.date : transaction.date
            }
            Section {
                ForEach(group) { transaction in
                    Button {
                        open(.addTransaction(id: transaction.id), in: section)
                    } label: {
                        transactionView(transaction: transaction)
                    }
                    .tag(transaction)
                    .cashly(tint: .text)
                    .cashlyDelete { Task { await transactions.delete(transaction) } }
                }
            } header: {
                CashlyHStack {
                    CashlyText(sectionDate?.formatted(.dateTime.day().month(.wide).year()))
                    Spacer()
                    CashlyText(sectionDate?.formatted(.dateTime.weekday(.wide)))
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
                    CashlyText(transaction.date.formatted(.dateTime.hour().minute()))
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
                            in: session.filter.isFilteringByDate
                                ? YearMonth(session.filter.startDate) : nil
                        ).formatted)
                } else if let paymentPlan = transaction.paymentsPlan {
                    CashlyHStack(spacing: .extraSmall) {
                        CashlyText("\(paymentPlan)x")
                            .cashly(color: .textSecondary)
                        CashlyText(
                            transaction.billingMoney(
                                in: session.filter.isFilteringByDate
                                    ? YearMonth(session.filter.startDate) : nil
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
        if !session.users.isEmpty, !isSelecting {
            Button {
                open(.addTransaction(id: nil), in: section)
            } label: {
                CashlySymbol("plus")
                    .cashly(color: .text)
            }
            .disabled(finance.isLoading)
        }
    }

    @ViewBuilder
    var editButton: some View {
        if !session.users.isEmpty, !isSelecting, !transactions.items.isEmpty {
            Button {
                withAnimation(.bouncy(duration: 0.8)) {
                    isSelecting = true
                }
            } label: {
                CashlySymbol("checkmark.circle")
                    .cashly(color: .text)
            }
            .disabled(finance.isLoading)
        }
    }

    @ViewBuilder
    var selectAllButton: some View {
        let isAllSelected = selection.count == transactions.items.count
        if isSelecting {
            Button {
                selection = isAllSelected ? [] : Set(transactions.items)
            } label: {
                CashlyText(isAllSelected ? "Clear Selection" : "Selecionar transações carregadas")
                    .cashly(font: .body, weight: .bold)
                    .cashly(color: .text)
            }
            .disabled(finance.isLoading)
        }
    }

    @ViewBuilder
    var shareButton: some View {
        if isSelecting {
            ShareLink(
                item: TransactionShareMessage.make(
                    transactions: selection, participants: session.filter.participants,
                    month: session.filter.isFilteringByDate
                        ? YearMonth(session.filter.startDate) : nil)
            ) {
                CashlySymbol("square.and.arrow.up")
                    .cashly(color: selection.isEmpty ? .disabled : .text)
            }
            .disabled(finance.isLoading)
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
            .disabled(finance.isLoading)
            .disabled(selection.isEmpty)
            .alert("Delete Transactions", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task { await transactions.delete(selection) }
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
            .disabled(finance.isLoading)
            .cashlyProminentButton()
        }
    }

}
