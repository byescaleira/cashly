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
    
    public func getTransaction(id: UUID) async throws -> CashlyDomain.Transaction? {
        let predicate: Predicate<TransactionEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return nil }
        return try await adapter.transactionAdapted(
            id: entity.id,
            user: entity.user,
            participants: entity.participants,
            category: entity.category,
            amount: entity.amount,
            date: entity.date,
            summary: entity.summary,
            status: entity.status
        )
    }
    
    public func getTransactions() async throws -> [CashlyDomain.Transaction] {
        let descriptor = FetchDescriptor<TransactionEntity>(sortBy: [.init(\.date, order: .reverse)])
        let entities = try modelContext.fetch(descriptor)
        var transactions = [CashlyDomain.Transaction]()
        for entity in entities {
            if let transaction = try await adapter.transactionAdapted(
                id: entity.id,
                user: entity.user,
                participants: entity.participants,
                category: entity.category,
                amount: entity.amount,
                date: entity.date,
                summary: entity.summary,
                status: entity.status
            ) {
                transactions.append(transaction)
            }
        }
        return transactions
    }
    
    public func getTransactions(
        budget: UUID?,
        category: UUID?,
        date: Date?
    ) async throws -> [CashlyDomain.Transaction] {
        var budgetEntity: BudgetEntity? = nil
        
        if let budget {
            let budgetPredicate: Predicate<BudgetEntity> = #Predicate {
                $0.id == budget
            }
            let budgetDescriptor = FetchDescriptor<BudgetEntity>(predicate: budgetPredicate)
            budgetEntity = try modelContext.fetch(budgetDescriptor).first
        }
        
        let budgetDate: Int? = budget == nil ? nil : budgetEntity == nil ? .zero : budgetEntity?.date.yearMonth
        let budgetCategory: UUID? = budget == nil ? nil : budgetEntity == nil ? .init() : budgetEntity?.category
        
        let predicateBudgetDate: Predicate<TransactionEntity> = #Predicate { transaction in
            budgetDate == nil ? true : transaction.date.yearMonth == budgetDate!
        }
        
        let predicateBudgetCategory: Predicate<TransactionEntity> = #Predicate { transaction in
            budgetCategory == nil ? true : transaction.category == budgetCategory!
        }
        
        let predicateCategory: Predicate<TransactionEntity> = #Predicate { transaction in
            category == nil ? true : transaction.category == category!
        }
        
        let predicateDate: Predicate<TransactionEntity> = #Predicate { transaction in
            date == nil ? true : transaction.date.yearMonth == date!.timeIntervalSince1970.yearMonth
        }
        
        let predicateAll: Predicate<TransactionEntity> = #Predicate {
            predicateBudgetDate.evaluate($0) &&
            predicateBudgetCategory.evaluate($0) &&
            predicateCategory.evaluate($0) &&
            predicateDate.evaluate($0)
        }
        
        let descriptor = FetchDescriptor<TransactionEntity>(
            predicate: predicateAll,
            sortBy: [.init(\.date, order: .reverse)]
        )
        
        let entities = try modelContext.fetch(descriptor)
        var transactions = [CashlyDomain.Transaction]()
        for entity in entities {
            if let transaction = try await adapter.transactionAdapted(
                id: entity.id,
                user: entity.user,
                participants: entity.participants,
                category: entity.category,
                amount: entity.amount,
                date: entity.date,
                summary: entity.summary,
                status: entity.status
            ) {
                transactions.append(transaction)
            }
        }
        return transactions
    }
    
    public func removeTransaction(id: UUID) async throws {
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
        id: UUID,
        user: User,
        participants: [User],
        category: CashlyDomain.Category,
        amount: Double,
        date: Date,
        summary: String,
        status: TransactionStatus
    ) async throws {
        let entity = TransactionEntity(
            id: id,
            user: user.id,
            participants: participants.map(\.id),
            category: category.id,
            amount: amount,
            date: date.timeIntervalSince1970,
            summary: summary,
            status: status.rawValue
        )
        modelContext.insert(entity)
        try modelContext.save()
    }
}
