//
//  TransactionActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import RyzeFoundation
import CashlyDomain
import SwiftData

public actor TransactionActor: TransactionUseCase {
    let modelContext: ModelContext
    let adapter: AdapterUseCase
    
    public init(
        modelContext: ModelContext,
        adapter: AdapterUseCase
    ) {
        self.modelContext = modelContext
        self.adapter = adapter
    }
    
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
            splitValue: entity.splitValue
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
                splitValue: entity.splitValue
            ) {
                transactions.append(transaction)
            }
        }
        return transactions
    }
    
    public func getTransactions(
        budgets: [String]?,
        tags: [String]?,
        date: Date?
    ) async throws -> [CashlyDomain.Transaction] {
        let predicateBudget: Predicate<String>
        if let budgets {
            predicateBudget = #Predicate { budgets.contains($0) }
        } else {
            predicateBudget = #Predicate { _ in true }
        }
        
        let predicateTag: Predicate<String>
        if let tags {
            predicateTag = #Predicate { tags.contains($0) }
        } else {
            predicateTag = #Predicate { _ in true }
        }
        
        let predicate: Predicate<TransactionEntity> = #Predicate {
            predicateBudget.evaluate($0.budget) &&
            predicateTag.evaluate($0.summary)
        }
        
        let descriptor = FetchDescriptor<TransactionEntity>(
            predicate: predicate,
            sortBy: [.init(\.date, order: .reverse)]
        )
        
        var entities = try modelContext.fetch(descriptor)
        if let date {
            let yearMonth = date.timeIntervalSince1970.yearMonth
            entities = entities.filter { $0.yearMonth == yearMonth }
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
                splitValue: entity.splitValue
            ) {
                transactions.append(transaction)
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
        splitValue: Double?
    ) async throws {
        let entity = TransactionEntity(
            id: id,
            participants: participants.map(\.id),
            budget: budget.id,
            amount: amount,
            date: date,
            summary: summary,
            status: status.rawValue,
            splitMode: splitMode?.rawValue,
            splitValue: splitValue
        )
        modelContext.insert(entity)
        try modelContext.save()
    }
}
