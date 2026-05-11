//
//  AddTransactionMiddleware.swift
//  CashlyKit
//

import CashlyDomain
import PrismArchitecture

public struct AddTransactionMiddleware: PrismMiddleware {
    let budgetUseCase: BudgetUseCase
    let categoryUseCase: CategoryUseCase
    let transactionUseCase: TransactionUseCase
    let tagUseCase: TagUseCase
    let userUseCase: UserUseCase
    let participantUseCase: ParticipantUseCase

    public init(
        budgetUseCase: BudgetUseCase,
        categoryUseCase: CategoryUseCase,
        transactionUseCase: TransactionUseCase,
        tagUseCase: TagUseCase,
        userUseCase: UserUseCase,
        participantUseCase: ParticipantUseCase
    ) {
        self.budgetUseCase = budgetUseCase
        self.categoryUseCase = categoryUseCase
        self.transactionUseCase = transactionUseCase
        self.tagUseCase = tagUseCase
        self.userUseCase = userUseCase
        self.participantUseCase = participantUseCase
    }

    public func run(state: AddTransactionState, action: AddTransactionAction) -> PrismEffect<AddTransactionAction> {
        switch action {
        case .fetch: return fetch(state: state)
        case .save: return save(state: state)
        case .remove: return remove(state: state)
        case .update: return .send(.stopLoading)
        case .stopLoading, .saved, .error, .replace: return .none
        }
    }

    private func fetch(state: AddTransactionState) -> PrismEffect<AddTransactionAction> {
        .run { send in
            do {
                let transaction = try await transactionUseCase.getTransaction(id: state.id)
                let currentUser = try await userUseCase.getCurrentUser()
                let categories = try await categoryUseCase.getCategories(
                    ids: nil, users: currentUser == nil ? nil : [currentUser?.id ?? ""]
                )
                let budgets = try await budgetUseCase.getBudgets(
                    categories: categories.isEmpty ? nil : categories.map(\.id),
                    date: state.date
                )
                let tags = try await tagUseCase.getTags(users: currentUser.map { [$0.id] })

                send(.update(
                    budgets: budgets,
                    id: transaction?.id ?? state.id,
                    participants: transaction?.participants ?? Array(state.participants),
                    budget: budgets.isEmpty ? nil : transaction?.budget ?? state.budget ?? budgets.first,
                    amount: transaction?.amount ?? state.amount,
                    date: transaction?.date.date ?? state.date,
                    summary: transaction?.summary ?? state.summary,
                    status: transaction?.status ?? state.status,
                    splitMode: transaction?.participants.first?.splitMode ?? state.splitMode,
                    splitValue: transaction?.splitValue ?? state.splitValue,
                    tags: tags,
                    isNew: transaction == nil,
                    installmentIsOn: transaction?.paymentsPlan != nil ? true : state.installmentIsOn,
                    installmentPlan: transaction?.paymentsPlan ?? state.installmentPlan
                ))
            } catch {
                send(.error(.persistence(.fetchFailed(entity: "Transaction", underlying: error.localizedDescription))))
            }
        }
    }

    private func save(state: AddTransactionState) -> PrismEffect<AddTransactionAction> {
        .run { send in
            do {
                let valueParticipants: Double = state.participants.compactMap {
                    $0.splitMode.value(splitValue: $0.splitValue, amount: state.amount)
                }.reduce(.zero, +)
                let value = state.splitValue ?? .zero < .zero ? .zero : state.splitValue ?? .zero
                let total = valueParticipants + value
                let isValidParticipants = Int(total - state.amount) == .zero

                guard let budget = state.budget else {
                    send(.error(.domain(.invalidInput(field: "budget", reason: "Budget is required."))))
                    return
                }
                guard state.amount > .zero else {
                    send(.error(.domain(.invalidInput(field: "amount", reason: "Amount must be greater than zero."))))
                    return
                }
                guard state.summary.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else {
                    send(.error(.domain(.invalidInput(field: "summary", reason: "Summary must be at least 3 characters."))))
                    return
                }
                guard state.participants.isEmpty || isValidParticipants else {
                    send(.error(.domain(.businessRuleViolated(rule: "Participant splits must sum to the transaction amount."))))
                    return
                }

                let status = state.participants.isEmpty ? state.status :
                state.participants.first(where: { $0.status != .settled })?.status.reverse ?? .settled

                for participant in state.participants {
                    try await participantUseCase.addParticipant(
                        id: participant.id, user: participant.user,
                        splitMode: participant.splitMode, splitValue: participant.splitValue,
                        status: participant.status, transaction: participant.transaction
                    )
                }

                try await transactionUseCase.addTransaction(
                    id: state.id,
                    participants: Array(state.participants),
                    budget: budget,
                    amount: state.amount,
                    date: state.date.timeIntervalSince1970,
                    summary: state.summary,
                    status: status,
                    splitMode: state.splitMode,
                    splitValue: state.splitValue,
                    paymentsPlan: state.installmentIsOn ? state.installmentPlan : nil
                )
                send(.saved)
            } catch {
                send(.error(.persistence(.saveFailed(entity: "Transaction", underlying: error.localizedDescription))))
            }
        }
    }

    private func remove(state: AddTransactionState) -> PrismEffect<AddTransactionAction> {
        .run { send in
            do {
                guard let transaction = try await transactionUseCase.getTransaction(id: state.id) else {
                    send(.error(.persistence(.notFound(entity: "Transaction", id: state.id))))
                    return
                }
                try await transactionUseCase.removeTransaction(id: transaction.id)
                send(.saved)
            } catch {
                send(.error(.persistence(.removeFailed(entity: "Transaction", underlying: error.localizedDescription))))
            }
        }
    }
}
