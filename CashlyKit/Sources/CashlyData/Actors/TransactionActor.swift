//
//  TransactionActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import Foundation
import CashlyDomain
import SwiftData

@ModelActor
public actor TransactionActor: TransactionUseCase {
    lazy var adapter: AdapterUseCase = AdapterActor(modelContainer: modelContainer)

    public func getTransaction(id: String) async throws -> CashlyDomain.Transaction? {
        let predicate: Predicate<TransactionEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return nil }
        return try await adapter.transactionAdapted(
            id: entity.id,
            participants: entity.participants,
            budget: entity.budget,
            amount: entity.amount,
            date: entity.date,
            summary: entity.summary,
            status: entity.status,
            splitMode: entity.splitMode,
            splitValue: entity.splitValue,
            paymentsPlan: entity.paymentsPlan
        )
    }

    public func getTransactions() async throws -> [CashlyDomain.Transaction] {
        let descriptor = FetchDescriptor<TransactionEntity>(sortBy: [.init(\.date, order: .reverse)])
        let entities = try modelContext.fetch(descriptor)
        var transactions = [CashlyDomain.Transaction]()
        for entity in entities {
            if let transaction = try await adapter.transactionAdapted(
                id: entity.id,
                participants: entity.participants,
                budget: entity.budget,
                amount: entity.amount,
                date: entity.date,
                summary: entity.summary,
                status: entity.status,
                splitMode: entity.splitMode,
                splitValue: entity.splitValue,
                paymentsPlan: entity.paymentsPlan
            ) {
                transactions.append(transaction)
            }
        }
        return transactions
    }

    public func getTransactions(
        budgets: [String]?,
        tags: [String]?,
        statuses: [Int]?,
        participants: [String]?,
        date: Date?
    ) async throws -> [CashlyDomain.Transaction] {
        let predicateBudget: Predicate<String>
        if let budgets {
            predicateBudget = #Predicate { budgets.contains($0) }
        } else {
            predicateBudget = #Predicate { _ in true }
        }

        let predicateStatus: Predicate<Int>
        if let statuses {
            predicateStatus = #Predicate { statuses.contains($0) }
        } else {
            predicateStatus = #Predicate { _ in true }
        }

        let predicate: Predicate<TransactionEntity> = #Predicate {
            predicateBudget.evaluate($0.budget) &&
            predicateStatus.evaluate($0.status)
        }

        let descriptor = FetchDescriptor<TransactionEntity>(
            predicate: predicate,
            sortBy: [.init(\.date, order: .reverse)]
        )

        var entities = try modelContext.fetch(descriptor)
        if let date {
            let yearMonth = date.timeIntervalSince1970.yearMonth
            entities = entities.filter {
                $0.paymentsPlan == nil ?
                ($0.yearMonth == yearMonth) :
                ($0.endDate?.contains(yearMonth) ?? false)
            }
        }

        if let tags {
            entities = entities.filter {
                let summary = $0.summary.lowercased()
                for tag in tags {
                    if summary.contains(tag) {
                        return true
                    }
                }
                return false
            }
        }

        var transactions = [CashlyDomain.Transaction]()
        for entity in entities {
            if let transaction = try await adapter.transactionAdapted(
                id: entity.id,
                participants: entity.participants,
                budget: entity.budget,
                amount: entity.amount,
                date: entity.date,
                summary: entity.summary,
                status: entity.status,
                splitMode: entity.splitMode,
                splitValue: entity.splitValue,
                paymentsPlan: entity.paymentsPlan
            ) {
                if let participants {
                    if transaction.participants.map(\.user.id).contains(participants) {
                        transactions.append(transaction)
                    }
                } else {
                    transactions.append(transaction)
                }
            }
        }

        return transactions
    }

    public func removeTransaction(id: String) async throws {
        let predicate: Predicate<TransactionEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(entity)
        try modelContext.save()
    }

    public func removeTransactions(ids: Set<String>) async throws {
        let predicate: Predicate<TransactionEntity> = #Predicate {
            ids.contains($0.id)
        }
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        let entities = try modelContext.fetch(descriptor)
        for entity in entities {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }

    public func removeTransactions() async throws {
        let descriptor = FetchDescriptor<TransactionEntity>()
        let entities = try modelContext.fetch(descriptor)
        for entity in entities {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }

    public func addTransaction(
        id: String,
        participants: [Participant],
        budget: Budget,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: TransactionStatus,
        splitMode: TransactionSplitMode?,
        splitValue: Double?,
        paymentsPlan: Int?
    ) async throws {
        let predicate: Predicate<TransactionEntity> = #Predicate { $0.id == id }
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        let entity = try modelContext.fetch(descriptor).first ?? TransactionEntity(
            id: id,
            participants: participants.map(\.id),
            budget: budget.id,
            amount: amount,
            date: date,
            summary: summary,
            status: status.rawValue,
            splitMode: splitMode?.rawValue,
            splitValue: splitValue,
            paymentsPlan: paymentsPlan
        )
        entity.id = id
        entity.participants = participants.map(\.id)
        entity.budget = budget.id
        entity.amount = amount
        entity.date = date
        entity.summary = summary
        entity.status = status.rawValue
        entity.splitMode = splitMode?.rawValue
        entity.splitValue = splitValue
        entity.paymentsPlan = paymentsPlan
        modelContext.insert(entity)
        try modelContext.save()
    }
}
